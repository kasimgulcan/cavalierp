using System.Xml.Linq;

namespace CsmStok.Api.Services;

public static class ProductImageFeedParser
{
    public static Dictionary<string, string> Parse(string xml)
    {
        var doc = XDocument.Parse(xml);
        var g = doc.Root?.GetNamespaceOfPrefix("g")
            ?? XNamespace.Get("http://base.google.com/ns/1.0");

        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        foreach (var item in doc.Descendants("item"))
        {
            var groupId = item.Element(g + "item_group_id")?.Value?.Trim();
            if (string.IsNullOrWhiteSpace(groupId))
                continue;

            var imageLink = item.Element(g + "image_link")?.Value?.Trim();
            if (string.IsNullOrWhiteSpace(imageLink))
                continue;

            if (!result.ContainsKey(groupId))
                result[groupId] = imageLink;
        }

        return result;
    }
}
