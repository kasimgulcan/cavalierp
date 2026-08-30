namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommerceTesterInboxItem
{
    public DateTimeOffset ReceivedAt { get; init; }
    public bool HmacValid { get; init; }
    public int StatusCode { get; init; }
    public string Body { get; init; } = string.Empty;
    public string Timestamp { get; init; } = string.Empty;
    public string Signature { get; init; } = string.Empty;
}

public sealed class EcommerceTesterInbox
{
    public const int Capacity = 100;
    private readonly object _gate = new();
    private readonly LinkedList<EcommerceTesterInboxItem> _items = [];

    public void Add(EcommerceTesterInboxItem item)
    {
        ArgumentNullException.ThrowIfNull(item);
        lock (_gate)
        {
            _items.AddFirst(item);
            while (_items.Count > Capacity)
                _items.RemoveLast();
        }
    }

    public IReadOnlyList<EcommerceTesterInboxItem> List()
    {
        lock (_gate)
            return _items.ToArray();
    }
}
