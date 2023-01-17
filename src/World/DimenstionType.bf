using System;

namespace Meteorite;

class DimensionType {
	public int minY;
	public int height;
	public int logicalHeight;
	public double coordinateScale;

	public bool hasCeiling;
	public bool hasSkylight;
	public bool ultrawarm;
	public bool natural;
	public bool bedWorks;
	public bool respawnAnchorWorks;

	public float ambientLight;

	public int64? fixedTime;

	public void Read(Tag tag) {
		minY = tag["min_y"].AsInt;
		height = tag["height"].AsInt;
		logicalHeight = tag["logical_height"].AsInt;
		coordinateScale = tag["coordinate_scale"].AsDouble;

		hasCeiling = tag["has_ceiling"].AsBool;
		hasSkylight = tag["has_skylight"].AsBool;
		ultrawarm = tag["ultrawarm"].AsBool;
		natural = tag["natural"].AsBool;
		bedWorks = tag["bed_works"].AsBool;
		respawnAnchorWorks = tag["respawn_anchor_works"].AsBool;

		ambientLight = tag["ambient_light"].AsFloat;

		if (tag.Contains("fixed_time")) fixedTime = tag["fixed_time"].AsLong;
	}
}