using System;
using System.IO;
using System.Collections;

namespace Cacti.Graphics;

typealias ShaderReadCallback = delegate Result<void>(StringView path, String output);

class ShaderPreProcessor {
	public struct Error : this(StringView file, int line, StringView message) {}

	public bool PreserveLineCount = true;

	private ShaderReadCallback readCallback ~ delete _;

	private append String errorFile = .();
	private append String errorMessage = .();

	public this() {
		readCallback = new (fileName, output) => {
			return .Err;
		};
	}

	public void SetReadCallback(ShaderReadCallback callback) {
		delete readCallback;
		readCallback = callback;
	}

	[Tracy.Profile]
	public Result<void> ReadShader(StringView path, String output) {
		return readCallback(path, output);
	}
	
	[Tracy.Profile]
	public Result<void, Error> PreProcess(StringView fileName, StringView source, Span<ShaderDefine> defines, String output) {
		// Create and setup context
		Context ctx = scope .(this, PreserveLineCount, output);
		ctx.PushFile(fileName);
		
		for (let define in defines) {
			ctx.Define(define.name, define.value).GetOrPropagateError!();
		}
		
		// Pre-process
		PreProcess(source, ctx).GetOrPropagateError!();

		// Add extensions
		AddExtensions(ctx).GetOrPropagateError!();

		// End context
		ctx.PopFile();

		return .Ok;
	}

	private Result<void, Error> PreProcess(StringView source, Context ctx) {
		int commentDepth = 0;

		int prevIfDepth = ctx.IfDepth;
		
		// Loop through the source line by line
		for (let line in Utils.Lines(source, false)) {
			ctx.line = @line.Index + 1;

			// Write empty line
			if (line.IsEmpty) {
				ctx.WriteLine();
				continue;
			}

			// Handle single-line comments
			if (line.StartsWith("//")) {
				ctx.WriteLine();
			}
			else {
				// Handle multi-line comments
				if (line.Contains("/*") || line.Contains("*/")) {
					String str = scope .();

					// Loop through character by character
					for (int i = 0; i < line.Length; i++) {
						char8 ch = line[i];

						mixin Next(char8 ch) {
							bool has = false;

							if (i + 1 < line.Length) {
								has = line[i + 1] == ch;
							}

							has
						}

						// Handle start
						if (ch == '/' && Next!('*')) {
							commentDepth++;
							i++;
						}
						// Handle end
						else if (ch == '*' && Next!('/')) {
							commentDepth--;
							i++;
						}
						// Other
						else if (commentDepth == 0) {
							str.Append(ch);
						}
					}

					// Write
					ctx.WriteLine(str);
				}
				else if (commentDepth == 0) {
					StringView trimmedLine = line;
					trimmedLine.Trim();

					// Handle pre-processor directives
					if (trimmedLine.StartsWith('#')) {
						StringSplitEnumerator split = trimmedLine.Split(' ', .RemoveEmptyEntries);
		
						StringView directive = ctx.Handle!(split.GetNext(), "Failed to parse directive")..Trim();
		
						// Handle if directives
						if (directive.Equals("#ifdef", true)) HandleIfDef(ctx, ref split, false).GetOrPropagateError!();
						else if (directive.Equals("#ifndef", true)) HandleIfDef(ctx, ref split, true).GetOrPropagateError!();
						else if (directive.Equals("#if", true)) HandleIf(ctx, ref split, true).GetOrPropagateError!();
						else if (directive.Equals("#else", true)) HandleElse(ctx).GetOrPropagateError!();
						else if (directive.Equals("#elif", true)) HandleElseIf(ctx, ref split).GetOrPropagateError!();
						else if (directive.Equals("#endif", true)) HandleEndIf(ctx).GetOrPropagateError!();
						// Handle non if directives if it passes the if checks
						else if (ctx.PassesIf) {
							if (directive.Equals("#define", true)) HandleDefine(ctx, trimmedLine, ref split).GetOrPropagateError!();
							else if (directive.Equals("#include", true)) HandleInclude(ctx, ref split).GetOrPropagateError!();
							else if (directive.Equals("#error", true)) HandleError(ctx, trimmedLine, ref split).GetOrPropagateError!();
							// Pass misc directives or report an error
							else {
								if (directive.Equals("#version", true) || directive.Equals("#extension", true)) ctx.WriteLine(line);
								else return ctx.GetError("Unknown pre processor directive");
							}
						}
						// Otherwise write an empty line to preserve line count
						else {
							ctx.WriteLine();
						}
					}
					// Normal code
					else HandleNormal(ctx, line).GetOrPropagateError!();
				}
				// Write an empty line to preserve line count
				else {
					ctx.WriteLine();
				}
			}
		}

		// Check for unterminated IF
		if (prevIfDepth != ctx.IfDepth) {
			return ctx.GetError("Unterminated IF");
		}
		
		return .Ok;
	}

	private Result<void, Error> AddExtensions(Context ctx) {
		int i = ctx.output.IndexOf('\n');
		ctx.output.Insert(i + 1, "#extension GL_GOOGLE_include_directive : require\n");

		return .Ok;
	}

	private Result<void, Error> HandleIfDef(Context ctx, ref StringSplitEnumerator split, bool negate) {
		StringView name = ctx.Handle!(split.GetNext(), "Failed to parse ifdef")..Trim();
		
		if (negate) ctx.PushIfChain(!ctx.IsDefined(name));
		else ctx.PushIfChain(ctx.IsDefined(name));
		
		ctx.WriteLine();
		return .Ok;
	}

	enum IfPart {
		case Value(bool val);
		case And;
		case Or;
	}

	private Result<void, Error> HandleIf(Context ctx, ref StringSplitEnumerator split, bool startsIfChain) {
		// Parse
		List<IfPart> parts = scope .();

		for (var part in split) {
			// And
			if (part == "&&") {
				parts.Add(.And);
			}
			// Or
			else if (part == "||") {
				parts.Add(.Or);
			}
			// Value
			else {
				// Negation
				bool negate = false;

				if (part.StartsWith('!')) {
					part = part[1...];
					negate = true;
				}

				// Defined
				if (part.StartsWith("defined(", .OrdinalIgnoreCase) && part.EndsWith(')')) {
					part = part[8...^2];

					bool value = ctx.IsDefined(part);
					if (negate) value = !value;

					parts.Add(.Value(value));
				}
				// Handle anything other as if it was wrapped in defined()
				else {
					StringView define;
					bool value = false;

					if (ctx.GetDefineValue(part, out define)) {
						if (define == "1" || define.Equals("true", true)) {
							value = true;
						}
					}

					if (negate) value = !value;

					parts.Add(.Value(value));
				}
			}
		}

		// Evaluate
		bool result = false;

		for (int i < parts.Count) {
			IfPart part = parts[i];

			// Value
			if (i == 0 && part case .Value(let val)) {
				result = val;
			}
			// And
			else if (i > 0 && part == .And) {
				// Get next part
				if (i + 1 >= parts.Count) return ctx.GetError("And operator needs to have a second value");
				IfPart next = parts[++i];

				// Evaluate
				if (next case .Value(let val)) {
					result = result && val;
				}
				else {
					return ctx.GetError("And operator needs to be followed by a value, not another operator");
				}
			}
			// Or
			else if (i > 0 && part == .Or) {
				// Get next part
				if (i + 1 >= parts.Count) return ctx.GetError("Or operator needs to have a second value");
				IfPart next = parts[++i];

				// Evaluate
				if (next case .Value(let val)) {
					result = result || val;
				}
				else {
					return ctx.GetError("Or operator needs to be followed by a value, not another operator");
				}
			}
			// Error
			else {
				return ctx.GetError("Unknown IF value or operator");
			}
		}

		// Push if
		if (startsIfChain) {
			ctx.PushIfChain(result);
		}
		else {
			IfChain* chain = ctx.LastIfChain.GetOrPropagateError!();

			chain.passedAny |= result;
			chain.passedLast = result;
		}

		// Write a new line to preserve line count
		ctx.WriteLine();
		return .Ok;
	}

	private Result<void, Error> HandleElse(Context ctx) {
		IfChain* chain = ctx.LastIfChain.GetOrPropagateError!();

		if (!chain.passedAny) {
			chain.passedAny = true;
			chain.passedLast = true;
		}
		else {
			chain.passedLast = false;
		}
		
		ctx.WriteLine();
		return .Ok;
	}

	private Result<void, Error> HandleElseIf(Context ctx, ref StringSplitEnumerator split) {
		IfChain* chain = ctx.LastIfChain.GetOrPropagateError!();

		if (!chain.passedAny) {
			return HandleIf(ctx, ref split, false);
		}

		chain.passedLast = false;
		return .Ok;
	}

	private Result<void, Error> HandleEndIf(Context ctx) {
		ctx.PopIfChain().GetOrPropagateError!();

		ctx.WriteLine();
		return .Ok;
	}

	private Result<void, Error> HandleDefine(Context ctx, StringView line, ref StringSplitEnumerator split) {
		StringView str = line[split.MatchPos ...]..Trim();

		int parenCount = 0;
		int splitI = str.Length;

		for (int i < str.Length) {
			char8 ch = str[i];

			if (ch == ' ' && parenCount == 0) {
				splitI = i;
				break;
			}
			else if (ch == '(') parenCount++;
			else if (ch == ')') {
				parenCount--;

				if (parenCount == 0) {
					splitI = i + 1;
					break;
				}
			}
		}

		StringView name;
		StringView value = "";

		if (splitI == str.Length) {
			name = str;
		}
		else {
			name = str[...splitI]..Trim();
			value = str[splitI...]..Trim();
		}

		ctx.Define(name, value).GetOrPropagateError!();

		ctx.WriteLine();
		return .Ok;
	}

	private Result<void, Error> HandleInclude(Context ctx, ref StringSplitEnumerator split) {
		// Get path
		StringView path = ctx.Handle!(split.GetNext(), "Failed to parse include")..Trim();
		
		// Absolute
		if (path.StartsWith('<') && path.EndsWith('>')) {
			path = path[1...^2];
		}
		// Relative
		else if (path.StartsWith('"') && path.EndsWith('"')) {
			path = path[1...^2];

			String final = Path.GetDirectoryPath(ctx.CurrentFile, .. scope:: .());
			Utils.CombinePath(final, path);
			
			if (Path.DirectorySeparatorChar != '/') {
				final.Replace(Path.DirectorySeparatorChar, '/');
			}

			path = final;
		}
		// Error
		else {
			return ctx.GetError("Include path needs to start and end either with <> or \"\"");
		}

		// Read file
		String source = scope .();

		if (ReadShader(path, source) == .Err) {
			return ctx.GetError(scope $"Failed to read shader file: {path}");
		}

		// Write File
		ctx.PushFile(path);
		PreProcess(source, ctx).GetOrPropagateError!();
		ctx.PopFile();

		return .Ok;
	}

	private Result<void, Error> HandleError(Context ctx, StringView line, ref StringSplitEnumerator split) {
		StringView message = line[split.MatchPos...]..Trim();
		return ctx.GetError(message);
	}

	private Result<void, Error> HandleNormal(Context ctx, StringView line) {
		// TODO: Make this faster
		ctx.temp1.Set(line);

		for (let define in ctx.Defines) {
			if (define.Replace(ctx.temp2, ctx.temp1) == .Err) {
				return ctx.GetError(scope $"Failed to apply define with name '{define.name}'");
			}
		}

		ctx.WriteLine(ctx.temp1);
		return .Ok;
	}

	struct IfChain {
		public bool passedAny;
		public bool passedLast;
	}

	class Context {
		private ShaderPreProcessor preProcessor;
		private append BumpAllocator alloc = .();

		public String temp1 = new:alloc .(512);
		public String temp2 = new:alloc .(512);

		private List<File> files = new:alloc .();

		private Dictionary<StringView, SDefine> defines = new:alloc .();
		private List<SDefine> sortedDefines = new:alloc .();

		private List<IfChain> ifChains = new:alloc .();

		private bool preserveLineCount;
		public String output;

		public int line;

		public Span<SDefine> Defines => sortedDefines;

		public this(ShaderPreProcessor preProcessor, bool preserveLineCount, String output) {
			this.preProcessor = preProcessor;
			this.preserveLineCount = preserveLineCount;
			this.output = output;
		}

		// Output

		public void WriteLine(StringView line = "", bool incrementLine = true) {
			if (preserveLineCount) {
				if (!line.IsEmpty && PassesIf) output.Append(line);

				output.Append('\n');
				if (incrementLine) files.Back.line++;
			}
			else {
				if (!line.IsEmpty && PassesIf) {
					output.Append(line);

					output.Append('\n');
					if (incrementLine) files.Back.line++;
				}
			}
		}

		// Files

		public void PushFile(StringView name) {
			if (!files.IsEmpty) {
				WriteLine(scope $"#line 1 \"{name}\"");
			}

			files.Add(.(name, 1));
		}

		public void PopFile() {
			files.PopBack();

			if (!files.IsEmpty) {
				File file = files.Back;
				WriteLine(scope $"#line {file.line} \"{file.name}\"", false);
			}
		}

		public StringView CurrentFile => files.Back.name;

		// Defines

		public Result<void, Error> Define(String name, String value) {
			SDefine define = CreateDefine(name, value).GetOrPropagateError!();
			defines[define.name] = define;

			sortedDefines.Add(define);
			SortDefines();

			return .Ok;
		}

		public Result<void, Error> Define(StringView name, StringView value) {
			String _name = new:alloc .(name);
			String _value = new:alloc .(value);

			SDefine define = CreateDefine(_name, _value).GetOrPropagateError!();
			defines[define.name] = define;

			sortedDefines.Add(define);
			SortDefines();

			return .Ok;
		}

		public Result<SDefine, Error> CreateDefine(StringView name, StringView value) {
			var name;

			List<StringView> parameters = null;

			int parameterCount = 0;
			SinglyLinkedList<DefinePart> parts = null;
			
			int i = name.IndexOf('(');

			if (i != -1) {
				// Parameters
				StringView parametersStr = name[(i + 1)...];
				name = name[...(i - 1)];

				if (!parametersStr.EndsWith(')')) return GetError<SDefine>("Define name contains a starting paren but not a closing one");
				parametersStr.Length--;

				parameters = new:alloc .();

				for (var parameter in parametersStr.Split(',', .RemoveEmptyEntries)) {
					parameters.Add(parameter..Trim());
				}

				parameterCount = parameters.Count;

				// Parts
				parts = new:alloc .();

				if (parameters.Count > 0) {
					// Split value to parameters
					List<StringView> valueParameters = scope .();

					for (var parameter in IdentifierEnumerator(value)) {
						parameter.Trim();

						if (parameters.Contains(parameter)) {
							valueParameters.Add(parameter);
						}
					}

					//     Append string before first argument
					{
						int j = valueParameters[0].Ptr - value.Ptr;
	
						if (j > 0) {
							parts.Add(.String(value[...(j - 1)]));
						}
					}
	
					//     Append strings between arguments and arguments themselves
					{
						StringView lastParameter = "";
	
						for (let parameter in valueParameters) {
							// Append string between arguments
							if (@parameter.Index > 0) {
								int lastI = (lastParameter.Ptr - value.Ptr) + lastParameter.Length;
								int j = parameter.Ptr - value.Ptr;
	
								if (lastI != j) {
									parts.Add(.String(value[lastI...(j - 1)]));
								}
							}
	
							// Append argument
							parts.Add(.Parameter(parameters.IndexOf(parameter)));
							lastParameter = parameter;
						}
					}
	
					//     Append string after last argument
					{
						int j = (valueParameters.Back.Ptr - value.Ptr) + valueParameters.Back.Length;
	
						if (j < value.Length) {
							parts.Add(.String(value[j...]));
						}
					}
				}
			}

			return SDefine(name, value, parameterCount, parts);
		}

		public bool IsDefined(StringView name) => defines.ContainsKeyAlt(name);

		public bool GetDefineValue(StringView name, out StringView value) {
			SDefine define;

			if (defines.TryGetValue(name, out define)) {
				value = define.value;
				return true;
			}

			value = "";
			return false;
		}

		private void SortDefines() {
			sortedDefines.Sort(scope (lhs, rhs) => Utils.ReverseComparison(lhs.name.Length <=> rhs.name.Length));
		}
		
		// Ifs

		public void PushIfChain(bool passed) {
			ifChains.Add(.() {
				passedAny = passed,
				passedLast = passed
			});
		}

		public Result<void, Error> UpdateIfChain(bool passed) {
			if (ifChains.IsEmpty) return GetError("No IF directive to end");

			var chain = ref ifChains.Back;

			chain.passedAny |= passed;
			chain.passedLast = passed;

			return .Ok;
		}

		public Result<void, Error> PopIfChain() {
			if (ifChains.IsEmpty) return GetError("No IF directive to end");

			ifChains.PopBack();
			return .Ok;
		}

		public Result<IfChain*, Error> LastIfChain { get {
			if (ifChains.IsEmpty) return GetError<IfChain*>("No IF directive to end");
			return &ifChains.Back;
		} }

		public bool PassesIf { get {
			if (ifChains.IsEmpty) return true;

			for (let chain in ifChains) {
				if (!chain.passedLast) return false;
			}

			return true;
		} }

		public int IfDepth => ifChains.Count;

		// Error handling

		public Result<T, Error> GetError<T>(StringView message) {
			preProcessor.errorFile.Set(CurrentFile);
			preProcessor.errorMessage.Set(message);

			return .Err(.(preProcessor.errorFile, line, preProcessor.errorMessage));
		}

		public Result<void, Error> GetError(StringView message) => GetError<void>(message);

		public mixin Handle<T>(Result<T> result, StringView message) {
			if (result == .Err) {
				return GetError<void>(message);
			}

			result.Value
		}
		
		// Other

		struct File : this(StringView name, int line) {}

		public enum DefinePart {
			case String(StringView str);
			case Parameter(int i);
		}
		
		public struct SDefine : this(StringView name, StringView value, int parameterCount, SinglyLinkedList<DefinePart> parts) {
			public Result<void> Replace(String temp, String str) {
				// Doesn't have parameters
				if (parameterCount == 0) {
					IdentifierEnumerator it = .(str);
					var result = it.GetNext();

					while (true) {
						if (result case .Ok(let val)) {
							if (val == name) {
								int start = val.Ptr - str.Ptr;
								Replace(str, start, val.Length, value);

								it = .(str[(start + value.Length)...]);
							}

							result = it.GetNext();
						}
						else break;
					}

					return .Ok;
				}

				// Does have parameters
				return ReplaceParameters(temp, str);
			}

			private Result<void> ReplaceParameters(String temp, String str) {
				int nameI = str.IndexOf(name);

				if (nameI != -1) {
					// Find view to replace and arguments view
					StringView toReplace;
					StringView argumentsStr;

					{
						if (FindUntilParensEnd(str[nameI...]) case .Ok(let val)) toReplace = val;
						else return .Ok;
	
						int parenI = toReplace.IndexOf('(');
						if (parenI == -1) return .Err;
	
						argumentsStr = toReplace[(parenI + 1)...];
	
						if (!argumentsStr.EndsWith(')')) return .Err;
						argumentsStr = argumentsStr[...^2];
					}
	
					// Extract arguments
					List<StringView> arguments = scope .();

					{
						if (!argumentsStr.IsEmpty) {
							while (true) {
								argumentsStr.Trim();
								if (argumentsStr.IsEmpty) break;
		
								int colonI = FindColonOutsideParens(argumentsStr);
	
								if (colonI == -1) {
									arguments.Add(argumentsStr);
									argumentsStr.Clear();
								}
								else {
									arguments.Add(argumentsStr[...(colonI - 1)]);
									argumentsStr.Adjust(colonI + 1);
								}
							}
						}
					}

					if (arguments.Count != parameterCount) return .Ok;

					// Create value replacement string
					temp.Clear();

					for (let part in parts) {
						switch (part) {
						case .String(let string):
							temp.Append(string);

						case .Parameter(let i):
							temp.Append(arguments[i]);
						}
					}

					// Replace
					Replace(str, toReplace.Ptr - str.Ptr, toReplace.Length, temp);

					// Recursive replace to handle multiple defines
					ReplaceParameters(temp, str).GetOrPropagate!();
				}

				return .Ok;
			}

			private Result<StringView> FindUntilParensEnd(StringView str, int maxI = int.MaxValue) {
				int colonCount = 0;

				for (int i < str.Length) {
					if (i > maxI) return .Err;

					char8 ch = str[i];

					if (ch == '(') colonCount++;
					else if (ch == ')') {
						colonCount--;

						if (colonCount == 0) {
							return str[...i];
						}
					}
				}

				return .Err;
			}

			private int FindColonOutsideParens(StringView str) {
				int colonCount = 0;

				for (int i < str.Length) {
					char8 ch = str[i];

					if (ch == ',' && colonCount == 0) return i;
					else if (ch == '(') colonCount++;
					else if (ch == ')') colonCount--;
				}

				return -1;
			}

			private void Replace(String str, int start, int length, StringView toReplace) {
				if (toReplace.IsEmpty) str.Remove(start, length);
				else str.Replace(start, length, toReplace);
			}
		}

		struct IdentifierEnumerator : IEnumerator<StringView> {
			private StringView str;
			private int i = 0;

			public this(StringView str) {
				this.str = str;
			}

			public Result<StringView> GetNext() mut {
				if (i >= str.Length) return .Err;

				// Move to start of an identifier
				if (!IsGood(i)) {
					while (true) {
						if (++i >= str.Length) return .Err;
						
						if (IsGood(i)) break;
					}
				}

				// Find identifier length
				int length = str.Length - i;

				for (int j = i; j < str.Length; j++) {
					if (!IsGood(j)) {
						length = j - i;
						break;
					}
				}

				StringView identifier = str.Substring(i, length);

				i += length;
				return identifier;
			}

			private bool IsGood(int i) {
				char8 ch = str[i];
				return ch.IsLetterOrDigit || ch == '_';
			}
		}
	}
}

public class ShaderDefine : IEquatable<Self>, IEquatable, IHashable {
	public String name, value;

	[AllowAppend]
	public this(StringView name, StringView value) {
		String _name = append .(name);
		String _value = append .(value);

		this.name = _name;
		this.value = _value;
	}

	[AllowAppend]
	public this(Self entry) : this(entry.name, entry.value) {}

	public bool Equals(Self other) => name == other.name && value == other.value;

	public bool Equals(Object other) => (other is Self) ? Equals((Self) other) : false;

	public int GetHashCode() => Utils.CombineHashCode(name.GetHashCode(), value.GetHashCode());

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
}