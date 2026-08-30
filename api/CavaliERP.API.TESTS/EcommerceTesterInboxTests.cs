using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class EcommerceTesterInboxTests
{
    [Fact]
    public void Add_StoresNewestFirst_AndCapsAt100()
    {
        var inbox = new EcommerceTesterInbox();

        for (var i = 0; i < 105; i++)
            inbox.Add(new EcommerceTesterInboxItem
            {
                ReceivedAt = DateTimeOffset.UnixEpoch.AddSeconds(i),
                HmacValid = true,
                StatusCode = 200,
                Body = i.ToString(),
            });

        var items = inbox.List();
        Assert.Equal(100, items.Count);
        Assert.Equal("104", items[0].Body);
        Assert.Equal("5", items[99].Body);
    }
}
