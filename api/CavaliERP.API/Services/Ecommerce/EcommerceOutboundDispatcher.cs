using System.Net;
using System.Net.Http.Headers;
using System.Text;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommerceOutboundDispatcher(
    IEcommerceStockRepository repository,
    IHttpClientFactory httpClientFactory,
    IOptions<EcommerceSyncOptions> options,
    ILogger<EcommerceOutboundDispatcher> logger)
{
    public const string HttpClientName = "EcommerceOutbound";
    public const int BatchSize = 20;

    public async Task ProcessOnceAsync(CancellationToken cancellationToken)
    {
        var opts = options.Value;
        if (!opts.Enabled || string.IsNullOrWhiteSpace(opts.SubscriberUrl) || string.IsNullOrWhiteSpace(opts.SharedSecret))
            return;

        IReadOnlyList<EcommerceOutboundRow> batch;
        try
        {
            batch = await repository.DequeuePendingAsync(BatchSize, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Ecommerce outbound dequeue failed.");
            return;
        }

        if (batch.Count == 0)
            return;

        var http = httpClientFactory.CreateClient(HttpClientName);
        foreach (var row in batch)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await DispatchRowAsync(http, opts, row, cancellationToken);
        }
    }

    private async Task DispatchRowAsync(
        HttpClient http,
        EcommerceSyncOptions opts,
        EcommerceOutboundRow row,
        CancellationToken cancellationToken)
    {
        var body = EcommerceOutboundPayload.ToJson(row);
        var timestamp = EcommerceHmac.UnixTimestamp(DateTimeOffset.UtcNow);
        var canonical = EcommerceHmac.CanonicalPost(timestamp, body);
        var signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(opts.SharedSecret, canonical));

        try
        {
            using var message = new HttpRequestMessage(HttpMethod.Post, opts.SubscriberUrl);
            message.Headers.TryAddWithoutValidation(EcommerceHmac.TimestampHeader, timestamp);
            message.Headers.TryAddWithoutValidation(EcommerceHmac.SignatureHeader, signature);
            if (!string.IsNullOrWhiteSpace(opts.SubscriberBearerToken))
                message.Headers.TryAddWithoutValidation("Authorization", "Bearer " + opts.SubscriberBearerToken.Trim());
            message.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            message.Content = new StringContent(body, Encoding.UTF8, "application/json");

            using var response = await http.SendAsync(message, cancellationToken);
            var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
            var status = (int)response.StatusCode;
            if (status is >= 200 and < 300)
            {
                await repository.MarkOutboundSentAsync(
                    row.OutboundId, opts.SubscriberUrl, body, status, responseBody, cancellationToken);
                return;
            }

            var error = EcommerceOutboundError.FormatHttp(response.StatusCode, responseBody);
            await repository.MarkOutboundAttemptAsync(
                row.OutboundId, error, row.Attempts + 1 >= 3, opts.SubscriberUrl, body, status, responseBody, cancellationToken);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning(ex, "Ecommerce outbound POST failed for {OutboundId}.", row.OutboundId);
            await repository.MarkOutboundAttemptAsync(
                row.OutboundId,
                EcommerceOutboundError.FormatException(ex),
                row.Attempts + 1 >= 3,
                opts.SubscriberUrl,
                body,
                httpStatus: null,
                responseJson: ex.Message,
                cancellationToken);
        }
    }
}

public sealed class EcommerceOutboundWorker(
    EcommerceOutboundDispatcher dispatcher,
    ILogger<EcommerceOutboundWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await dispatcher.ProcessOnceAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Ecommerce outbound worker cycle failed.");
            }

            try
            {
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }
}
