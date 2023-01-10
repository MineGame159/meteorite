using System;
using System.Reflection;
using System.Collections;

namespace Cacti {
	[AttributeUsage(.Types)]
	struct AutoConstructorAttribute : Attribute, IOnTypeInit {
		[Comptime]
		public void OnTypeInit(Type type, Self* prev) {
			// Get fields
			List<FieldInfo> fields = scope .();

			for (let field in type.GetFields()) {
				if (field.IsPublic) fields.Add(field);
			}

			// Parameters
			Compiler.EmitTypeBody(type, "public this(\n");

			for (let field in fields) {
				Compiler.EmitTypeBody(type, scope $"	{field.FieldType} {field.Name}");

				if (@field.Index < fields.Count - 1) Compiler.EmitTypeBody(type, ",\n");
				else Compiler.EmitTypeBody(type, "\n");
			}

			Compiler.EmitTypeBody(type, ") {\n");

			// Body
			for (let field in fields) {
				Compiler.EmitTypeBody(type, scope $"	this.{field.Name} = {field.Name};\n");
			}

			Compiler.EmitTypeBody(type, "}");
		}
	}
}