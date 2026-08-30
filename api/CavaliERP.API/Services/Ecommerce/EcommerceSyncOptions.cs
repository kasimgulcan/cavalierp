namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommerceSyncOptions
{
    public const string SectionName = "EcommerceSync";

    public bool Enabled { get; set; }

    public bool TesterEnabled { get; set; } = true;

    public string SharedSecret { get; set; } = string.Empty;

    public string SubscriberUrl { get; set; } = string.Empty;

    public int? ActorUserId { get; set; } = 7;

    public int TimestampSkewMinutes { get; set; } = 5;

    public string[] AllowedCidrs { get; set; } = [];
}
