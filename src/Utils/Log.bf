using System;

namespace Meteorite {
	class Log {
		public static void Trace(StringView fmt, params Object[] args) {
			Console.ForegroundColor = .DarkGray;
			String str = scope .();
			AppendHeader(str, "TRACE");
			str.AppendF(fmt, params args);
			Console.WriteLine(str);
		}

		public static void Debug(StringView fmt, params Object[] args) {
			Console.ForegroundColor = .DarkGray;
			String str = scope .();
			AppendHeader(str, "DEBUG");
			str.AppendF(fmt, params args);
			Console.WriteLine(str);
		}

		public static void Chat(StringView fmt, params Object[] args) {
			Console.ForegroundColor = .Gray;
			String str = scope .();
			AppendHeader(str, "CHAT");
			str.AppendF(fmt, params args);
			Console.WriteLine(str);
		}

		public static void Info(StringView fmt, params Object[] args) {
			Console.ForegroundColor = .White;
			String str = scope .();
			AppendHeader(str, "INFO");
			str.AppendF(fmt, params args);
			Console.WriteLine(str);
		}

		public static void Warning(StringView fmt, params Object[] args) {
			Console.ForegroundColor = .Yellow;
			String str = scope .();
			AppendHeader(str, "WARNING");
			str.AppendF(fmt, params args);
			Console.WriteLine(str);
		}

		public static void Error(StringView fmt, params Object[] args) {
			Console.ForegroundColor = .Red;
			String str = scope .();
			AppendHeader(str, "ERROR");
			str.AppendF(fmt, params args);
			Console.WriteLine(str);
		}

		private static void AppendHeader(String str, StringView name) {
#if BF_PLATFORM_WINDOWS
			DateTime time = .Now;
			str.AppendF("[{:D2}:{:D2}:{:D2}] {}: ", time.Hour, time.Minute, time.Second, name);
#else
			str.AppendF("{}: ", name);
#endif
		}
	}
}