using System;

using Cacti;

namespace Meteorite {
	static class CubicSampler {
		private const double[?] DENSITY_CURVE = .(0.0, 1.0, 4.0, 6.0, 4.0, 1.0, 0.0);

		public typealias RgbFetcher = delegate Vec3f(int x, int y, int z);

		public static Vec3f SampleColor(Vec3f pos, RgbFetcher rgbFetcher) {
			int i = (.) Math.Floor(pos.x);
			int j = (.) Math.Floor(pos.y);
			int k = (.) Math.Floor(pos.z);
			double d = pos.x - i;
			double e = pos.y - j;
			double f = pos.z - k;
			double g = 0.0;
			Vec3f vec3d = .();

			for (int l = 0; l < 6; ++l) {
			    double h = Math.Lerp(DENSITY_CURVE[l + 1], DENSITY_CURVE[l], d);
			    int m = i - 2 + l;

			    for (int n = 0; n < 6; ++n) {
			        double o = Math.Lerp(DENSITY_CURVE[n + 1], DENSITY_CURVE[n], e);
			        int p = j - 2 + n;

			        for (int q = 0; q < 6; ++q) {
			            double r = Math.Lerp(DENSITY_CURVE[q + 1], DENSITY_CURVE[q], f);
			            int s = k - 2 + q;
			            double t = h * o * r;
			            g += t;
						
			            vec3d += rgbFetcher(m, p, s) * (float) t;
			        }
			    }
			}
			vec3d *= (float) (1 / g);
			return vec3d;
		}
	}
}