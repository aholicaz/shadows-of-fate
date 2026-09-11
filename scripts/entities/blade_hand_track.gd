extends RefCounted

# Original 512px cells: x/y = grip, z = rotation relative to the Idle sword,
# w = scale relative to the 1120px-wide Idle source. One sample per body frame.
const POSES := {
	"Attack_Blade": [
		Vector4(181, 248, 45, 0.42), Vector4(172, 215, 68, 0.42),
		Vector4(176, 169, 104, 0.42), Vector4(177, 156, 125, 0.42),
		Vector4(201, 257, -93, 0.42)],
	"Attack_Blade_2": [
		Vector4(285, 221, 104, 0.42), Vector4(283, 233, 112, 0.42),
		Vector4(166, 194, -37, 0.42), Vector4(163, 184, -17, 0.42),
		Vector4(160, 188, 16, 0.42)],
	"Attack_Blade_3": [
		Vector4(271, 112, 140, 0.42), Vector4(261, 118, 159, 0.42),
		Vector4(259, 118, 168, 0.42), Vector4(260, 118, 172, 0.42),
		Vector4(260, 118, 158, 0.42), Vector4(205, 316, -62, 0.42),
		Vector4(211, 316, -62, 0.42), Vector4(209, 316, -62, 0.42),
		Vector4(209, 316, -62, 0.42), Vector4(188, 307, -29, 0.42),
		Vector4(191, 288, 9, 0.42), Vector4(189, 268, 25, 0.42)]
}
