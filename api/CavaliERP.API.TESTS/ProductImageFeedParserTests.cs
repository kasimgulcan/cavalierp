using CsmStok.Api.Services;

namespace CsmStok.Api.Tests;

public class ProductImageFeedParserTests
{
    [Fact]
    public void Parse_MapsItemGroupIdToFirstImageLink()
    {
        const string xml = """
            <?xml version="1.0"?>
            <rss version="2.0" xmlns:g="http://base.google.com/ns/1.0">
              <channel>
                <item>
                  <g:item_group_id>R.TOPWN_TTS0064_SUP0025BLKBLK</g:item_group_id>
                  <g:image_link>https://cdn.example/first.jpeg</g:image_link>
                </item>
                <item>
                  <g:item_group_id>R.TOPWN_TTS0064_SUP0025BLKBLK</g:item_group_id>
                  <g:image_link>https://cdn.example/second.jpeg</g:image_link>
                </item>
              </channel>
            </rss>
            """;

        var result = ProductImageFeedParser.Parse(xml);

        Assert.Single(result);
        Assert.Equal("https://cdn.example/first.jpeg", result["R.TOPWN_TTS0064_SUP0025BLKBLK"]);
        Assert.Equal("https://cdn.example/first.jpeg", result["r.topwn_tts0064_sup0025blkblk"]);
    }
}
