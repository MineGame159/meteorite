using System;
using System.Reflection;

namespace Meteorite;

abstract class PacketHandler {
	protected Meteorite me = .INSTANCE;

	public abstract void OnConnectionLost();

	public abstract S2CPacket GetPacket(int32 id);

	public abstract void Handle(S2CPacket packet);

	protected mixin CheckPacketCondition(S2CPacket packet) {
		if (packet.requires == .World && me.world == null) return;
		if (packet.requires == .Player && (me.world == null || me.player == null)) return;
	}
}

[AttributeUsage(.Class)]
struct PacketHandlerImplAttribute : Attribute, IOnTypeInit {
	[Comptime]
	public void OnTypeInit(Type type, Self* prev) {
		// GetPacket()
		Compiler.EmitTypeBody(type, """
			public static S2CPacket GetPacket(int32 id) {
				switch (id) {

			""");

		for (let method in type.OuterType.GetMethods(.Instance)) {
			if (method.ParamCount != 1) continue;

			Type packet = method.GetParamType(0);
			if (packet == typeof(S2CPacket) || !packet.IsSubtypeOf(typeof(S2CPacket))) continue;

			if (packet.IsAbstract) {
				for (let attribute in packet.GetCustomAttributes<PacketSubTypeAttribute>()) {
					Compiler.EmitTypeBody(type, scope $"	case {attribute.type}.ID: return new {attribute.type}();\n");
				}
			}
			else {
				Compiler.EmitTypeBody(type, scope $"	case {packet}.ID: return new {packet}();\n");
			}
		}

		Compiler.EmitTypeBody(type, """
				}

				return null;
			}


			""");

		// Dispatch()
		Compiler.EmitTypeBody(type, scope $"""
			public static void Dispatch({type.OuterType} handler, S2CPacket packet) {{
				defer delete packet;
				handler.[Friend]CheckPacketCondition!(packet);

				switch (packet.id) {{

			""");

		for (let method in type.OuterType.GetMethods(.Instance)) {
			if (method.ParamCount != 1) continue;

			Type packet = method.GetParamType(0);
			if (packet == typeof(S2CPacket) || !packet.IsSubtypeOf(typeof(S2CPacket))) continue;

			if (packet.IsAbstract) {
				for (let attribute in packet.GetCustomAttributes<PacketSubTypeAttribute>()) {
					Compiler.EmitTypeBody(type, scope $"	case {attribute.type}.ID: handler.{method.Name}((.) packet);\n");
				}
			}
			else {
				Compiler.EmitTypeBody(type, scope $"	case {packet}.ID: handler.{method.Name}((.) packet);\n");
			}
		}

		Compiler.EmitTypeBody(type, """
				}
			}
			""");
	}
}