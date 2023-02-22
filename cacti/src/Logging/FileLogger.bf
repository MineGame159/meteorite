using System;
using System.IO;

namespace Cacti {
	class FileLogger : ILogger {
		private StreamWriter writer ~ delete _;
	
		public this(StringView fileName) {
			// Create directory
			String directory = scope .();

			if (Path.GetDirectoryPath(fileName, directory) == .Ok) {
				if (Directory.CreateDirectory(directory) case .Err) {
					Log.Error("Failed to create directory: {}", directory);
					return;
				}
			}

			// Create writer
			FileStream fs = new .();
			fs.Create(fileName, .Write, .Read);
			
			writer = new StreamWriter(fs, .ASCII, 4096, true);
		}
	
		public void Log(Message message) {
			writer.WriteLine(message.text);
			writer.Flush();
		}
	}
}