using System;
using System.Collections;

namespace Meteorite {
	class ShaderPreProcessor {
		private Dictionary<String, String> defines = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
		private List<(String, String)> list = new .() ~ delete _;

		public void Define(StringView name, StringView value = "") {
			String name_ = new .(name);
			String value_ = value == "" ? null : new .(value);

			if (defines.ContainsKey(name_)) {
				for (let a in list) {
					if (a.0 == name_) {
						@a.Remove();
						break;
					}
				}

				let result = defines.GetAndRemove(name_);
				delete result.Value.key;
				delete result.Value.value;
			}

			defines[name_] = value_;
			list.Add((name_, value_));
			list.Sort(scope (a, b) => b.0.Length <=> a.0.Length);

			list = list;
		}

		public void PreProcess(StringView path, String buffer) => PreProcess(path, buffer, true);

		private void ApplyDefines(String buffer) {
			for (let define in list) {
				if (define.1 == null) continue;

				buffer.Replace(define.0, define.1);
			}
		}

		private void PreProcess(StringView path, String buffer, bool first) {
			var first;
			bool comment = false;
			List<bool> ifs = scope .();
			String final = scope .();

			Meteorite.INSTANCE.resources.ReadLines(path, scope [&](line) => {
				StringView lineTrimmed = line;
				lineTrimmed.Trim();

				if (comment) {
					if (lineTrimmed.EndsWith("*/")) comment = false;
					return;
				}

				if (lineTrimmed.StartsWith("//")) return;
				if (lineTrimmed.StartsWith("/*")) {
					comment = true;
					return;
				}

				if (first && !lineTrimmed.StartsWith("#version ")) buffer.Append("#version 450\n");
				first = false;

				if (lineTrimmed.StartsWith('#')) {
					if (lineTrimmed.StartsWith("#ifdef ")) {
						StringView define = lineTrimmed[7...];
						ifs.Add(defines.ContainsKey(scope .(define)));
						return;
					}
					else if (lineTrimmed.StartsWith("#ifndef ")) {
						StringView define = lineTrimmed[7...];
						ifs.Add(!defines.ContainsKey(scope .(define)));
						return;
					}
					else if (lineTrimmed.StartsWith("#elif ")) {
						StringView define = lineTrimmed[6...];
						ifs.PopBack();
						ifs.Add(defines.ContainsKey(scope .(define)));
						return;
					}
					else if (lineTrimmed.StartsWith("#else")) {
						ifs.Add(!ifs.PopBack());
						return;
					}
					else if (lineTrimmed.StartsWith("#endif")) {
						ifs.PopBack();
						return;
					}

					if (ifs.IsEmpty || ifs.Back) {
						if (lineTrimmed.StartsWith("#define ")) {
							StringView rest = lineTrimmed[8...];

							if (rest.Contains(' ')) {
								let i = rest.IndexOf(' ');

								StringView value = rest[(i + 1)...];
								value.TrimStart();

								final.Set(value);
								ApplyDefines(final);

								Define(rest[0...(i - 1)], final);
							}
							else Define(rest);

							return;
						}
						else if (lineTrimmed.StartsWith("#include ")) {
							StringView include = lineTrimmed[9...];
							PreProcess(scope $"shaders/{include}.glsl", buffer, false);
							return;
						}
					}
				}

				if (ifs.IsEmpty || ifs.Back) {
					final.Set(line);
					ApplyDefines(final);

					buffer.Append(final);
					buffer.Append('\n');
				}
			});
		}
	}
}