globalize_all_functions

int function ArmoryUtil_WeightedRound( float x ) {
	int intPart = x.tointeger()
	float floatPart = x - intPart

	return (RandomFloatRange( 0.0, 1.0 ) > fabs( floatPart )) ? intPart : intPart + 1
}

float function ArmoryUtil_SmoothMin( float a, float b, float k ) {
    float h = max( k - fabs(a - b), 0.0 ) / k;
    return min( a, b ) - h*h * k * (1.0 / 4.0);
}

vector function ArmoryUtil_VecHadamard( vector a, vector b ) {
	return Vector(a.x * b.x, a.y * b.y, a.z * b.z)
}