using System.Net;
using System.Net.Sockets;

namespace CsmStok.Api.Services.Ecommerce;

public static class EcommerceIpAllowlist
{
    public static bool IsAllowed(IPAddress? address, IReadOnlyList<string> cidrs)
    {
        if (cidrs.Count == 0)
            return true;

        if (address is null)
            return false;

        if (address.IsIPv4MappedToIPv6)
            address = address.MapToIPv4();

        foreach (var cidr in cidrs)
        {
            if (string.IsNullOrWhiteSpace(cidr))
                continue;

            if (Matches(address, cidr.Trim()))
                return true;
        }

        return false;
    }

    private static bool Matches(IPAddress address, string cidr)
    {
        var slash = cidr.LastIndexOf('/');
        IPAddress network;
        int prefixLength;

        if (slash < 0)
        {
            if (!IPAddress.TryParse(cidr, out network!))
                return false;
            prefixLength = network.AddressFamily == AddressFamily.InterNetwork ? 32 : 128;
        }
        else
        {
            if (!IPAddress.TryParse(cidr[..slash], out network!))
                return false;
            if (!int.TryParse(cidr[(slash + 1)..], out prefixLength))
                return false;
        }

        if (network.AddressFamily != address.AddressFamily)
            return false;

        var addressBytes = address.GetAddressBytes();
        var networkBytes = network.GetAddressBytes();
        if (addressBytes.Length != networkBytes.Length)
            return false;

        var maxPrefix = addressBytes.Length * 8;
        if (prefixLength < 0 || prefixLength > maxPrefix)
            return false;

        var fullBytes = prefixLength / 8;
        var remainingBits = prefixLength % 8;

        for (var i = 0; i < fullBytes; i++)
        {
            if (addressBytes[i] != networkBytes[i])
                return false;
        }

        if (remainingBits == 0)
            return true;

        var mask = (byte)(0xFF << (8 - remainingBits));
        return (addressBytes[fullBytes] & mask) == (networkBytes[fullBytes] & mask);
    }
}
