 ////-------------//
 ///**NFAA Fast**///
 //-------------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Normal Filter Anti Aliasing.
 //* For ReShade 3.0+ & Freestyle
 //*  ---------------------------------
 //*                                                                          NFAA
 //* Due Diligence
 //* Based on port by b34r
 //* https://www.gamedev.net/forums/topic/580517-nfaa---a-post-process-anti-aliasing-filter-results-implementation-details/?page=2
 //* Later rewritten by Eric B. AKA Kourinn
 //* https://github.com/BlueSkyDefender/AstrayFX/pull/17
 //* If I missed any please tell me.
 //*
 //* LICENSE
 //* ============
 //* Normal Filter Anti Aliasing is licenses under: Attribution-NoDerivatives 4.0 International
 //*
 //* You are free to:
 //* Share - copy and redistribute the material in any medium or format
 //* for any purpose, even commercially.
 //* The licensor cannot revoke these freedoms as long as you follow the license terms.
 //* Under the following terms:
 //* Attribution - You must give appropriate credit, provide a link to the license, and indicate if changes were made.
 //* You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
 //*
 //* NoDerivatives - If you remix, transform, or build upon the material, you may not distribute the modified material.
 //*
 //* No additional restrictions - You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
 //*
 //* https://creativecommons.org/licenses/by-nd/4.0/
 //*
 //* Have fun,
 //* Jose Negrete AKA BlueSkyDefender
 //*
 //* https://github.com/BlueSkyDefender/Depth3D
 //*
 //* Have fun,
 //* Jose Negrete AKA BlueSkyDefender
 //*
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define BUFFER_PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define BUFFER_ASPECT_RATIO (BUFFER_WIDTH * BUFFER_RCP_HEIGHT)

uniform int EdgeDetectionType <
	ui_type = "combo";
    ui_items = "Luminance edge detection\0Perceived Luminance edge detection\0Color edge detection\0Perceived Color edge detection\0";
    ui_label = "Edge Detection Type";
> = 3;

uniform float EdgeDetectionThreshold <
	ui_type = "drag";
    ui_label = "Edge Detection Threshold";
    ui_tooltip = "The difference in Luminence/Color that would be perceived as an edge.\n" 
                 "Try lowering this slightly if the Edge Mask misses some edges.\n"
                 "Default is 0.063";
    ui_min = 0.050; ui_max = 0.200; ui_step = 0.001;
> = 0.100;

uniform float EdgeSearchRadius <
	ui_type = "drag";
    ui_label = "Edge Search Radius";
    ui_tooltip = "The radius to search for edges.\n"
                 "Try raising this if using in-game upscaling.\n"
                 "Default is 1.000";
    ui_min = 0.000; ui_max = 4.000; ui_step = 0.001;
> = 1.000;

uniform float UnblurFilterStrength <
	ui_type = "drag";
    ui_label = "Unblur Filter Strength";
    ui_tooltip = "Adjusts the Edge Mask and Corner Mask contrast for filtering unwanted edge blur.\n"
                 "Try raising this if text or icons become blurry.\n"
                 "Try lowering this if edges are still too aliased.\n"
                 "Default is 1.000";
    ui_min = 0.000; ui_max = 2.000; ui_step = 0.001;
> = 1.000;

uniform float BlurStrength <
	ui_type = "drag";
    ui_label = "Blur Strength";
    ui_tooltip = "Adjusts the Normal Map weights for stronger edge blur.\n"
                 "Try raising this if edges are still too aliased.\n"
                 "Try lowering this if text or icons become blurry.\n"
                 "Default is 1.000";
    ui_min = 0.000; ui_max = 2.000; ui_step = 0.001;
> = 1.000;

uniform float2 BlurSize <
	ui_type = "drag";
    ui_label = "Blur Size";
    ui_tooltip = "Adjusts the Normal Map depth for larger/longer edge blur.\n"
                 "Inputs are blur size parallel and perpendicular to the edge respectively.\n"
                 "Try raising this if edges are still too aliased.\n"
                 "Try lowering this if text or icons become blurry.\n"
                 "Defaults are 2.000 and 1.000";
    ui_min = 0.000; ui_max = 4.000; ui_step = 0.001;
> = float2(2.000, 1.000);

uniform int DebugOutput <
	ui_type = "combo";
    ui_label = "Debug Output";
    ui_items = "None\0Edge Mask View\0Corner Mask View\0Normal Map View\0Pre-Blur Mask View\0Post-Blur Mask View\0";
    ui_tooltip = "Edge Mask View shows the Edge Detection and Unblur Filter Strength.\n"
                 "Corner Mask View shows the Corner Detection and Unblur Filter Strength.\n"
                 "Normal Map View shows the Normal Map depth, used for Blur Size and Blur Direction.\n"
                 "Pre-Blur Mask View shows just the edges that will be blurred.\n"
                 "Post-Blur Mask View shows just the edges have been blurred.";
    ui_spacing = 2;
> = 0;

////////////////////////////////////////////////////////////Variables////////////////////////////////////////////////////////////////////

// sRGB Luminance
static const float3 LinearizeVector[4] = { float3(0.2126, 0.7152, 0.0722), float3(0.299, 0.587, 0.114), float3(0.3333333, 0.3333333, 0.3333333), float3(0.299, 0.587, 0.114) };

static const float Cos45 = 0.70710678118654752440084436210485;

static const float MaxSlope = 1024.0;

texture BackBufferTex : COLOR;

sampler BackBuffer { Texture = BackBufferTex; };

////////////////////////////////////////////////////////////Functions////////////////////////////////////////////////////////////////////

float LinearDifference(float3 A, float3 B)
{
    float lumDiff = dot(A, LinearizeVector[EdgeDetectionType]) - dot(B, LinearizeVector[EdgeDetectionType]);
    if (EdgeDetectionType < 2)
        return lumDiff;
    
    float3 C = abs(A - B);
    return max(max(C.r, C.g), C.b) * (lumDiff < 0.0 ? -1.0 : 1.0); // sign intrinsic can return 0, which we don't want. Plus this is faster.
}

float2 Rotate45(float2 p) {
    return float2(mad(p.x, Cos45, -p.y * Cos45), mad(p.x, Cos45, p.y * Cos45));
    // return float2(p.x * Cos45 - p.y * Cos45, p.x * Cos45 + p.y * Cos45);
}

////////////////////////////////////////////////////////////NFAA////////////////////////////////////////////////////////////////////

float4 NFAA(float2 texcoord, float4 offsets[4])
{
    float4 color = tex2Dlod(BackBuffer, float4(texcoord, 0.0, 0.0));

    // Find Edges
    //  +---+---+---+---+---+
    //  |   |   |   |   |   |
    //  +---+---+---+---+---+
    //  |   | e | f | g |   |
    //  +---+--(a)-(b)--+---+
    //  |   | h | P | i |   |
    //  +---+--(c)-(d)--+---+
    //  |   | j | k | l |   |
    //  +---+---+---+---+---+
    //  |   |   |   |   |   |
    //  +---+---+---+---+---+
    // Much better at horizontal/vertical lines, slightly better diagonals, always compares 6 pixels, not 2.
    float3 a = tex2Dlod(BackBuffer, offsets[0]).rgb;
    float3 b = tex2Dlod(BackBuffer, offsets[1]).rgb;
    float3 c = tex2Dlod(BackBuffer, offsets[2]).rgb;
    float3 d = tex2Dlod(BackBuffer, offsets[3]).rgb;

    // Original edge detection from b34r & BlueSkyDefender
    //  +---+---+---+---+---+
    //  |   |   |   |   |   |
    //  +---+---+---+---+---+
    //  |   |   | t |   |   |
    //  +---+---+---+---+---+
    //  |   | l | C | r |   |
    //  +---+---+---+---+---+
    //  |   |   | b |   |   |
    //  +---+---+---+---+---+
    //  |   |   |   |   |   |
    //  +---+---+---+---+---+
    // float angle = 0.0;
    // float3 t = tex2Dlod(BackBuffer, float4(mad(float2(0.0, -EdgeSearchRadius), BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0)).rgb;
    // float3 b = tex2Dlod(BackBuffer, float4(mad(float2(-0.0, EdgeSearchRadius), BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0)).rgb;
    // float3 r = tex2Dlod(BackBuffer, float4(mad(float2(EdgeSearchRadius, 0.0), BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0)).rgb;
    // float3 l = tex2Dlod(BackBuffer, float4(mad(float2(-EdgeSearchRadius, 0.0), BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0)).rgb;
    // float2 n = float2(LinearDifference(t, b), LinearDifference(r, l));

    // i.e. top vs bottom = a + b - (c + d) = (e + 2*f + g) / 4 - (j + 2*k + l) / 4
    float2 normal = float2(LinearDifference(b + d, a + c), LinearDifference(c + d, a + b)); // right - left, bottom - top
    float edge = length(normal);

    float edgeMask = 1.0;
    float cornerMask = 1.0;
    if (edge > EdgeDetectionThreshold)
    {
        // Lets make that edgeMask for a sharper image.
        float edgeConfidence = log2(edge / EdgeDetectionThreshold);
        edgeMask = saturate(mad(edgeConfidence, UnblurFilterStrength - 2.0, 1.0));
        // edgeMask = saturate((1.0 - (UnblurFilterStrength - 2.0) * edgeConfidence);

        // Then subtract corners from edge mask to avoid bluring text and detailed icons
        float4 corners = float4(LinearDifference(a + b + c, 3.0 * d), LinearDifference(a + b + d, 3.0 * c), LinearDifference(a + c + d, 3.0 * b), LinearDifference(c + d + b, 3.0 * a));
        float corner = dot(abs(corners), 0.25);
        cornerMask = saturate(edgeMask + corner);

        // calculate x/y coordinates along the edge at specified distances and offsets
        // +---+---+---+---+---+ +---+---+---+---+---+
        // |   |   |   |   |   | |   |   |   |   |   |
        // +---+---+---+---+---+ +---+---+---+---+---+
        // |   |   |   |   |   | |   |   | (e)   |   |
        // +---+(g)a---b(e)+---+ +---+---a---b(f)+---+
        // |   |-O | P | O |   | |   |   | P |   |   |
        // +---+(h)c---d(f)+---+ +---+(g)c---d---+---+
        // |   |   |   |   |   | |   |   (h) |   |   |
        // +---+---+---+---+---+ +---+---+---+---+---+
        // |   |   |   |   |   | |   |   |   |   |   |
        // +---+---+---+---+---+ +---+---+---+---+---+

        // slope m = normal.r / normal.g
        // distance d
        // y = mx
        // d^2 = y^2 + x^2 = (mx)^2+x^2
        // d^2 = x^2(1 + m^2)
        // x^2 = d^2/(1 + m^2)

        // Follow the edge for 1/2 of BlurSize.x
        float4 offset;
        float m = normal.g != 0 ? normal.r / normal.g : MaxSlope;
        float d = 0.5 * BlurSize.x;
        offset.x = sqrt(d *d / (1.0 + m * m));
        offset.y = m * offset.x;
        // Then move perpendicular to the edge for 1/2 of BlurSize.y
        m = normal.r != 0 ? -normal.g / normal.r : MaxSlope;
        d = 0.5 * BlurSize.y;
        offset.z = sqrt(d * d / (1.0 + m * m));
        offset.w = m * offset.z;

        float3 e = tex2Dlod(BackBuffer, float4(mad(offset.xy + offset.zw, BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0)).rgb;
        float3 f = tex2Dlod(BackBuffer, float4(mad(offset.xy - offset.zw, BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0)).rgb;
        float3 g = tex2Dlod(BackBuffer, float4(mad(-offset.xy - offset.zw, BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0)).rgb;
        float3 h = tex2Dlod(BackBuffer, float4(mad(-offset.xy + offset.zw, BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0)).rgb;

        // It's possible to reduce taps by re-using edge detection taps a, b, c, d,
        // but it's not worth it. Nearby pixels should already be cached, and it would need more math.

        // apply blur
        if (DebugOutput != 4)
            color.rgb = lerp(color.rgb, (e + f + g + h) * 0.25, BlurStrength * 0.5 * (1.0 - cornerMask));
        
        // Pre/Post Blur Mask
        if (DebugOutput > 3)
            color.a = cornerMask;

        // original blur from b34r & BlueSkyDefender
        // may need some work to be functional again, due to some variable name refactoring after I reversed how/why it worked
        // +---+---+---+---+---+
        // |   |   |   |   |   |
        // +---+---+---+---+---+
        // |\\\|   | x | x |   |
        // +---+---+---+---+---+
        // |   |\\\|\\\| x |   |
        // +---+---+---+---+---+
        // |   |   | x |\\\|\\\|
        // +---+---+---+---+---+
        // |   |   |   |   |   |
        // +---+---+---+---+---+
        // y = -0.5x; n.x = 1; n.y = 0.5; nl = 1.18; dn.x = 0.85; dn.y = 0.42;
        // t0/1 = 0.425, 0.21; d ~= 0.5
        // t2/3 = 0.765, -0.38; d ~= 0.85
        // float2 dn = n / nl * BlurSize;
        // float4 t0 = tex2Dlod(BackBuffer, float4(mad(-dn * 0.5, BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0));
        // float4 t1 = tex2Dlod(BackBuffer, float4(mad(dn * 0.5, BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0));
        // float4 t2 = tex2Dlod(BackBuffer, float4(mad(float2(dn.x, -dn.y) * 0.9, BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0));
        // float4 t3 = tex2Dlod(BackBuffer, float4(mad(float2(-dn.x, dn.y) * 0.9, BUFFER_PIXEL_SIZE, texcoord), 0.0, 0.0));
        // color = lerp(mad(color, 0.23, 0.175 * (t2 + t3) + 0.21 * (t0 + t1)), color, edgeMask);
    }
    else {
        color.a = 0.0;
    }

    if(DebugOutput == 1) // Edge Mask
    {
        color.rgb = edgeMask;
    }
    if(DebugOutput == 2) // Corner Mask
    {
        color.rgb = cornerMask;
    }
    else if (DebugOutput == 3) // Normal Map
    {
        // Normal map, right = red, green = top, configured using white box with black background
        float3 normalMap;
        normalMap.b = 1.0;
        normalMap.rg = mad(float2(-normal.r, normal.g) * BlurSize.x * BlurStrength, 0.25, 0.5);
        normalMap.rg = lerp(float2(0.5, 0.5), saturate(normalMap.rg), (1.0 - edgeMask) * BlurSize.y);
        color.rgb = normalMap;
    }
    else if (DebugOutput > 3) { // Pre/Post Blur Mask
        uint row = floor(texcoord.y / 0.1);
        uint col = floor(texcoord.x * BUFFER_ASPECT_RATIO / 0.1);

        float3 lightGray = 0.5;
        float3 darkGray = 0.1667;
        
        lightGray = lerp(lightGray, color.rgb, color.a);
        darkGray = lerp(darkGray, color.rgb, color.a);

        // Create checkerboad background to depict transparency
        if (row % 2 == 0) {
            if (col % 2 == 0) {
                color.rgb = lightGray;
            }
            else {
                color.rgb = darkGray;
            }
        }
        else {
            if (col % 2 == 0) {
                color.rgb = darkGray;
            }
            else {
                color.rgb = lightGray;
            }
        }
        
    }

    color.a = 1.0;
    return color;
}

void NFAA_VS(in uint id : SV_VertexID, out float4 position : SV_POSITION, out float2 texcoord : TEXCOORD, out float4 offsets[4] : TEXCOORD1 )
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    
	float2 offset = Cos45 * EdgeSearchRadius * BUFFER_PIXEL_SIZE;
    offsets[0] = float4(mad(float2(-1.0, -1.0), offset, texcoord), 0.0, 0.0);
    offsets[1] = float4(mad(float2(1.0, -1.0),  offset, texcoord), 0.0, 0.0);
    offsets[2] = float4(mad(float2(-1.0, 1.0), offset, texcoord), 0.0, 0.0);
    offsets[3] = float4(mad(float2(1.0, 1.0), offset, texcoord), 0.0, 0.0);
}

float4 NFAA_PS(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, in float4 offsets[4] : TEXCOORD1) : SV_Target
{
    return NFAA(texcoord, offsets);
}

technique NFAA
{
        pass NFAA_Fast
        {
            VertexShader = NFAA_VS;
            PixelShader = NFAA_PS;
        }
}
