using System;

using Cacti;

namespace Meteorite;

class ChatType {
	public String translationKey ~ delete _;
	public String[] parameters ~ DeleteContainerAndItems!(_);
	public Color color;

	public this(StringView translationKey, String[] parameters, Color color) {
		this.translationKey = new .(translationKey);
		this.parameters = parameters;
		this.color = color;
	}
}