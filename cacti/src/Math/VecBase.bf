using System;
using System.Reflection;

namespace Cacti;

/*[AttributeUsage(.Struct)]
struct VecBaseAttribute : this(int components), Attribute, IOnTypeInit {
	[Comptime]
	public void OnTypeInit(Type type, Self* prev) {
		String string = scope .();

		// Constants
		{
			string.Set("""
				public const Self ZERO = .(0);
				public const Self ONE = .(1);


				""");

			Compiler.EmitTypeBody(type, string);
		}

		// Fields
		{
			string.Set("public T ");
			GetComponentsString(false, string);
			string.Append(";\n\n");
	
			Compiler.EmitTypeBody(type, string);
		}

		// Constructors
		{
			// Main
			string.Set("public this(");
			GetComponentsString(true, string);
			string.Append(") {\n");
	
			for (int i < components) {
				string.AppendF("	this.{0} = {0};\n", GetComponentName(i));
			}
	
			string.Append("}\n\n");
			Compiler.EmitTypeBody(type, string);
	
			// Single
			string.Set("public this(T value) {\n");
	
			for (int i < components) {
				string.AppendF("	this.{} = value;\n", GetComponentName(i));
			}
	
			string.Append("}\n\n");
			Compiler.EmitTypeBody(type, string);
		}

		// Indexing
		{
			string.Set("""
				public T this[int index] {
					get {
						switch (index) {
	
				""");
	
			for (int i < components) {
				string.AppendF("		case {}: return {};\n", i, GetComponentName(i));
			}
	
			string.Append("""
						default: Runtime.FatalError();
						}
					}
					set mut {
						switch (index) {
	
				""");
	
			for (int i < components) {
				string.AppendF("		case {}: {} = value;\n", i, GetComponentName(i));
			}
	
			string.Append("""
						default: Runtime.FatalError();
						}
					}
				}
	
	
				""");
	
			Compiler.EmitTypeBody(type, string);
		}

		// Basic properties
		{
			// Is zero
			string.Set("public bool IsZero => ");

			for (int i < components) {
				if (i > 0) string.Append(" && ");
				string.AppendF("{} == 0", GetComponentName(i));
			}

			string.Append(";\n\n");

			// Length squared
			string.Append("public double LengthSquared => ");

			for (int i < components) {
				if (i > 0) string.Append(" + ");
				string.AppendF("{0} * {0}", GetComponentName(i));
			}

			string.Append(";\n\n");

			// Length
			string.Append("public double Length => Math.Sqrt(LengthSquared);\n\n");

			Compiler.EmitTypeBody(type, string);
		}

		// Conversions
		{
			mixin Conversion(StringView to) {
				string.AppendF("public Vec{0}<{1}> {2} => Vec{0}<{1}>(", components, to, Utils.Capitalize(.. scope .(to)));

				for (int i < components) {
					if (i > 0) string.Append(", ");
					string.AppendF("(.) {}", GetComponentName(i));
				}

				string.Append(");\n");
			}

			string.Clear();

			Conversion!("float");
			Conversion!("double");
			Conversion!("int");

			string.Append('\n');
			Compiler.EmitTypeBody(type, string);
		}

		// Basic methods
		{
			// Normalize
			string.Set("""
				public Self Normalize() {
					double l = Length;
					return .(
				""");

			for (int i < components) {
				if (i > 0) string.Append(", ");
				string.AppendF("(.) ({} / l)", GetComponentName(i));
			}

			string.Append(");\n}\n\n");

			// Dot
			string.Append("public double Dot(Self vec) => ");

			for (int i < components) {
				if (i > 0) string.Append(" + ");
				string.AppendF("{0} + vec.{0}", GetComponentName(i));
			}

			string.Append(";\n\n");

			// Clamp
			string.Append("public Self Clamp(T min, T max) => .(");

			for (int i < components) {
				if (i > 0) string.Append(", ");
				string.AppendF("Math.Clamp({}, min, max)", GetComponentName(i));
			}

			string.Append(");\n\n");

			// Lerp
			string.Append("public Self Lerp(double delta, Self end) => .(");

			for (int i < components) {
				if (i > 0) string.Append(", ");
				string.AppendF("Utils.Lerp(delta, {0}, end.{0})", GetComponentName(i));
			}

			string.Append(");\n\n");

			Compiler.EmitTypeBody(type, string);
		}

		// Equals
		{
			string.Set("public bool Equals(Self vec) => ");
	
			for (int i < components) {
				if (i > 0) string.Append(" && ");
				string.AppendF("{0} == vec.{0}", GetComponentName(i));
			}
	
			string.Append("""
				;
				public bool Equals(Object other) => (other is Self) ? Equals((Self) other) : false;
	
				[Commutable]
				public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
	
	
				""");
	
			Compiler.EmitAddInterface(type, typeof(IEquatable));
			Compiler.EmitTypeBody(type, string);
		}

		// Hashable
		{
			string.Set("""
				public int GetHashCode() {
					int hash = 0;
	
				""");

			for (int i < components) {
				string.AppendF("	Utils.CombineHashCode(ref hash, {});\n", GetComponentName(i));
			}
	
			string.Append("""
					return hash;
				}
	
	
				""");
	
			Compiler.EmitAddInterface(type, typeof(IHashable));
			Compiler.EmitTypeBody(type, string);
		}

		// To string
		{
			// [{:0.00}, {:0.00}]
			string.Set("public override void ToString(String str) => str.AppendF(\"[");

			for (int i < components) {
				if (i > 0) string.Append(", ");
				string.Append("{:0.00}");
			}

			string.Append("]\", ");
			GetComponentsString(false, string);
			string.Append(");\n\n");

			Compiler.EmitTypeBody(type, string);
		}

		// Math operators
		{
			mixin Operator(char8 op) {
				string.AppendF("public static Self operator{}(Self lhs, Self rhs) => .(", op);

				for (int i < components) {
					if (i > 0) string.Append(", ");
					string.AppendF("lhs.{0} {1} rhs.{0}", GetComponentName(i), op);
				}

				string.AppendF("""
					);
					[Commutable]
					public static Self operator{}(Self lhs, T rhs) where T : INumeric => .(
					""", op);

				for (int i < components) {
					if (i > 0) string.Append(", ");
					string.AppendF("lhs.{} {} rhs", GetComponentName(i), op);
				}

				string.Append(");\n");
			}

			string.Clear();

			Operator!('+');
			Operator!('-');
			Operator!('*');
			Operator!('/');
			Operator!('%');

			string.Append("\n");
			Compiler.EmitTypeBody(type, string);
		}

		// Comparison operators
		{
			string.Set("""
				public static bool operator>(Self lhs, Self rhs) => lhs.LengthSquared > rhs.LengthSquared;
				[Commutable]
				public static bool operator>(Self lhs, T rhs) where T : INumeric => lhs.LengthSquared > rhs;
				public static bool operator<(Self lhs, Self rhs) => lhs.LengthSquared < rhs.LengthSquared;
				[Commutable]
				public static bool operator<(Self lhs, T rhs) where T : INumeric => lhs.LengthSquared < rhs;
				""");

			Compiler.EmitTypeBody(type, string);
		}
	}

	private void GetComponentsString(bool includeType, String string) {
		for (int i < components) {
			if (i > 0) string.Append(", ");

			if (includeType) string.Append("T ");
			string.Append(GetComponentName(i));
		}
	}

	private char8 GetComponentName(int component) {
		switch (component) {
		case 0:		return 'x';
		case 1: 	return 'y';
		case 2: 	return 'z';
		case 3: 	return 'w';
		default:	Runtime.FatalError();
		}
	}
}*/