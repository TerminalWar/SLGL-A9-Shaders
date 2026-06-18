vec3 project_and_divide(mat4 Projection_mat, vec3 x) {
    vec4 HomogeneousPos = Projection_mat * vec4(x, 1);
    return HomogeneousPos.xyz / HomogeneousPos.w;
}

vec3 screen_view(vec3 x, bool IsDH) {
    x = x * 2 - 1;

    mat4 ProjMat = IsDH ? dhProjectionInverse : gbufferProjectionInverse;
    return project_and_divide(ProjMat, x);
}

vec3 view_player(vec3 x, bool IsDH) {
    return mat3(gbufferModelViewInverse) * x;
}

vec3 player_view(vec3 x, bool IsDH) {
    return mat3(gbufferModelView) * x;
}

vec3 view_screen(vec3 x, bool IsDH) {
    mat4 ProjMat = IsDH ? dhProjection : gbufferProjection;
    x = project_and_divide(ProjMat, x);

    x = x * 0.5 + 0.5;
    return x;
}

vec3 player_shadow(vec3 PlayerPos) {
    vec3 ShadowPos = project_and_divide(shadowProjection, (shadowModelView * vec4(PlayerPos + gbufferModelViewInverse[3].xyz, 1)).xyz); //convert to shadow ndc space
    return ShadowPos;
}


#define to_linear(sRGB) ( sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878) )
