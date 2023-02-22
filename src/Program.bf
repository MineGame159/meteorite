using System;

using Cacti;
using Cacti.Graphics;

namespace Meteorite;

class ProgramArgs {
	public bool logFile;
	public bool renderdoc;
	public bool vulkanValidation;
	public bool debugLog;

	public this() {
#if DEBUG
		renderdoc = true;
		vulkanValidation = true;
		debugLog = true;
#endif
	}
}

class Program {
	public static append ProgramArgs ARGS = .();

	public static void Main(String[] args) {
		// Setup options
		CLI cli = scope .(args);

		cli.Option("log-file", 'l', "Writes log output to a file named run/latest.log", ref ARGS.logFile);
		cli.Option("renderdoc", 'r', "Attaches a RenderDoc instance to Meteorite" , ref ARGS.renderdoc);
		cli.Option("vulkan-validation", 'v', "Starts Meteorite with Vulkan validation layer enabled", ref ARGS.vulkanValidation);
		cli.Option("debug-log", 'd', "Enables logging of debug messages", ref ARGS.debugLog);

		// Apply options
		Log.AddLogger(new ConsoleLogger());
		if (ARGS.logFile) Log.AddLogger(new FileLogger("run/latest.log"));
		
		Gfx.VULKAN_VALIDATION = ARGS.vulkanValidation;

		if (ARGS.debugLog) {
			Log.MIN_LEVEL = .Debug;
		}

		// Start Meteorite
		if (cli.Run) {
			if (ARGS.renderdoc) {
				RenderDoc.Init();
			}
											
			scope Meteorite().Run();
		}
	}
}

class CLI {
	private String[] args;
	private bool help;

	public bool Run => !help;

	public this(String[] args) {
		this.args = args;

		Search("help", 'h', ref help);

		if (help) {
			Console.WriteLine("Meteorite - Minecraft client written in Beef");
			Console.WriteLine();

			PrintHelp("help", 'h', "Prints this message");
		}
	}

	public void Option(StringView long, char8 short, StringView description, ref bool value) {
		if (help) {
			PrintHelp(long, short, description);
		}
		else {
			Search(long, short, ref value);
		}
	}

	private void PrintHelp(StringView long, char8 short, StringView description) {
		Console.WriteLine("\t-{}, --{,-20} - {}", short, long, description);
	}

	private void Search(StringView long, char8 short, ref bool value) {
		for (String arg in args) {
			if (arg.StartsWith("--")) {
				if (arg.Substring(2) == long) value = true;
			}
			else if (arg.StartsWith('-')) {
#unwarn
				if (arg.Substring(1) == StringView(&short, 1)) value = true;
			}
		}
	}
}