using System;
using System.Collections;

namespace Meteorite {
	struct Mipmap : IDisposable {
		public int w, h;
		public uint8* pixels;
		public bool ownsPixels;

		public this(int w, int h, uint8* pixels, bool ownsPixels) {
			this.w = w;
			this.h = h;
			this.pixels = pixels;
			this.ownsPixels = ownsPixels;
		}

		public void Dispose() {
			if (ownsPixels) delete pixels;
		}
	}

	static class MipmapGenerator {
		private static double[256] colorFractions;
		private static bool initialized;

		private static uint8 GetColorComponent(uint8 a, uint8 b, uint8 c, uint8 d) {
		    double a2 = colorFractions[a];
		    double b2 = colorFractions[b];
		    double c2 = colorFractions[c];
		    double d2 = colorFractions[d];

		    double j = Math.Pow((a2 + b2 + c2 + d2) * 0.25, 0.45454545454545453);
		    return (uint8) (j * 255.0);
		}

		private static Color Blend(Color c1, Color c2, Color c3, Color c4, bool checkAlpha) {
		    if (checkAlpha) {
		        double r = 0;
		        double g = 0;
		        double b = 0;
		        double a = 0;

		        if (c1.a != 0) {
		            r += colorFractions[c1.r];
		            g += colorFractions[c1.g];
		            b += colorFractions[c1.b];
		            a += colorFractions[c1.a];
		        }

		        if (c2.a != 0) {
		            r += colorFractions[c2.r];
		            g += colorFractions[c2.g];
		            b += colorFractions[c2.b];
		            a += colorFractions[c2.a];
		        }

		        if (c3.a != 0) {
		            r += colorFractions[c3.r];
		            g += colorFractions[c3.g];
		            b += colorFractions[c3.b];
		            a += colorFractions[c3.a];
		        }

		        if (c4.a != 0) {
		            r += colorFractions[c4.r];
		            g += colorFractions[c4.g];
		            b += colorFractions[c4.b];
		            a += colorFractions[c4.a];
		        }

		        r /= 4.0;
		        g /= 4.0;
		        b /= 4.0;
		        a /= 4.0;

		        uint8 r2 = (.) (Math.Pow(r, 0.45454545454545453) * 255.0);
		        uint8 g2 = (.) (Math.Pow(g, 0.45454545454545453) * 255.0);
		        uint8 b2 = (.) (Math.Pow(b, 0.45454545454545453) * 255.0);
		        uint8 a2 = (.) (Math.Pow(a, 0.45454545454545453) * 255.0);

		        if (a2 < 96) a2 = 0;

		        return .(r2, g2, b2, a2);
		    }

		    return .(
		            GetColorComponent(c1.r, c2.r, c3.r, c4.r),
		            GetColorComponent(c1.g, c2.g, c3.g, c4.g),
		            GetColorComponent(c1.b, c2.b, c3.b, c4.b),
		            GetColorComponent(c1.a, c2.a, c3.a, c4.a)
		    );
		}

		private static void Init() {
			for (int i < 256) {
			    colorFractions[i] = Math.Pow(i / 255.0, 2.2);
			}

			initialized = true;
		}

		private static mixin Index(int x, int y, int h) {
			(y * h + x) * 4
		}

		public static void Generate(uint8* originalPixels, int originalW, int originalH, int count, List<Mipmap> images) {
			if (!initialized) Init();

			int w = originalW;
			int h = originalH;

			bool checkAlpha = false;

			afterCheckAlpha:
			for (int x = 0; x < w; x++) {
			    for (int y = 0; y < h; y++) {
			        if (originalPixels[Index!(x, y, h) + 3] == 0) {
			            checkAlpha = true;
			            break afterCheckAlpha;
			        }
			    }
			}

			for (int i = 0; i < count; i++) {
			    if (i == 0) {
			        images.Add(.(w, h, originalPixels, false));
			        continue;
			    }

			    Mipmap prev = images[i - 1];
			    Color* prevColors = (.) prev.pixels;

			    w /= 2;
			    h /= 2;

			    uint8* newPixels = new uint8[w * h * 4]*;
			    Color* newColors = (.) newPixels;

			    for (int x = 0; x < w; x++) {
			        for (int y = 0; y < h; y++) {
			            newColors[y * h + x] = Blend(
							prevColors[(y * 2) * prev.h + x * 2],
		                    prevColors[(y * 2) * prev.h + x * 2 + 1],
		                    prevColors[(y * 2 + 1) * prev.h + x * 2],
		                    prevColors[(y * 2 + 1) * prev.h + x * 2 + 1],
		                    checkAlpha
			            );
			        }
			    }

			    images.Add(.(w, h, newPixels, true));
			}
		}
	}
}