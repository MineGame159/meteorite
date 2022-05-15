using System;
using System.Collections;
using System.IO;

using static Meteorite.GL;

namespace Meteorite {
	class Shaderb {
		private static float[4] COLOR;

		private uint id ~ glDeleteProgram(_);
		private Dictionary<String, int> locations = new .() ~ DeleteDictionaryAndKeys!(_);

		public this(StringView vertexStr, StringView fragmentStr, bool paths = true) {
			// Vertex shader
			uint vert = glCreateShader(GL_VERTEX_SHADER);

			if (paths) {
				String source = new String();
				defer delete source;

				if (File.ReadAllText(vertexStr, source) case .Err) Log.Error("Failed to read file '{}'", vertexStr);
				char8* str = source.CStr();
				glShaderSource(vert, 1, &str, null);
			}
			else {
				char8* str = vertexStr.ToScopeCStr!();
				glShaderSource(vert, 1, &str, null);
			}

			glCompileShader(vert);

			int32 success = 0;
			glGetShaderiv(vert, GL_COMPILE_STATUS, &success);

			if (success == 0) {
			    char8[512] infoLog = default;
			    glGetShaderInfoLog(vert, 512, null, &infoLog);
				Log.Error("Failed to compile vertex shader: {}", infoLog);
			}

			// Fragment shader
			uint frag = glCreateShader(GL_FRAGMENT_SHADER);

			if (paths) {
				String source = new String();
				defer delete source;

				if (File.ReadAllText(fragmentStr, source) case .Err) Log.Error("Failed to read file '{}'", fragmentStr);
				char8* str = source.CStr();
				glShaderSource(frag, 1, &str, null);
			}
			else {
				char8* str = fragmentStr.ToScopeCStr!();
				glShaderSource(frag, 1, &str, null);
			}

			glCompileShader(frag);

			success = 0;
			glGetShaderiv(frag, GL_COMPILE_STATUS, &success);

			if (success == 0) {
			    char8[512] infoLog = default;
			    glGetShaderInfoLog(frag, 512, null, &infoLog);
				Log.Error("Failed to compile fragment shader: {}", infoLog);
			}

			// Program
			id = glCreateProgram();

			glAttachShader(id, vert);
			glAttachShader(id, frag);
			glLinkProgram(id);

			success = 0;
			glGetProgramiv(id, GL_LINK_STATUS, &success);

			if (success == 0) {
			    char8[512] infoLog = default;
			    glGetProgramInfoLog(id, 512, null, &infoLog);
				Log.Error("Failed to link shader program: {}", infoLog);
			}

			// Delete shaders
			glDetachShader(id, vert);
			glDetachShader(id, frag);

			glDeleteShader(vert);
			glDeleteShader(frag);
		}

		public void Bind() => glUseProgram(id);

		public int GetLocation(String name) {
			String _;
			int location;
			if (locations.TryGet(name, out _, out location)) return location;

			location = glGetUniformLocation(id, name.CStr());
			locations[new String(name)] = location;
			return location;
		}

		public void Set(int location, int32 v) => glProgramUniform1i(id, location, v);
		public void Set(String name, int32 v) => Set(GetLocation(name), v);

		public void Set(int location, Vec2 v) => glProgramUniform2f(id, location, v.x, v.y);
		public void Set(String name, Vec2 v) => Set(GetLocation(name), v);

		public void Set(int location, Color c) {
			COLOR[0] = c.R;
			COLOR[1] = c.G;
			COLOR[2] = c.B;
			COLOR[3] = c.A;
			glProgramUniform4fv(id, location, 1, &COLOR);
		}
		public void Set(String name, Color c) => Set(GetLocation(name), c);

		public void Set(int location, Mat4 m) {
			float[16] f = m.floats;
			glProgramUniformMatrix4fv(id, location, 1, GL_FALSE, &f);
		}
		public void Set(String name, Mat4 m) => Set(GetLocation(name), m);

	}
}