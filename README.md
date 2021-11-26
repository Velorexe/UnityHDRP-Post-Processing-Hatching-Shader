# Unity HDRP Post Processing Hatching Shader

<p align="center">
    A Post Processing shader featuring Hatching based on World Space UV's in the Unity HDRP<br>
    <i>Project for a minor in Game Development & Simulation at the Hague University of Applied Sciences</i>
</p>

<p align="center">
    <img src="https://i.imgur.com/BOqI20Z.png">
</p>

## How does it work?
By calculating the world space UV's based on the Camera's view, it can overlay an image by using these UV's on a tiled sketch texture. The sketch texture is divided into 3 "different" textures, based on how intense the hatching effect has to be. The intensity is based on the brightness of the pixel it's applying the effect to.

**Features**
* Post Processing Shader (`HatchingPostProcessing.shader`)
* The Post Processing effect script (`HatchingEffect.cs`)
* 3 example stroke textures (`/Strokes`)

## Help
You can use [this](https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@7.1/manual/Custom-Post-Process.html) guide to add a custom post processing effect to your Unity project. Make sure that you're using the HDRP pipeline, since I'm not sure how the effect turns out if you use a different pipeline.

## Resources
* [`Real-Time Hatching`](https://hhoppe.com/hatching.pdf) by Microsoft Research
* [`Hatching`](https://github.com/aillieo/unity3d-shaders-practice/blob/master/Assets/Chapter_14/Shaders/Hatching.shader) by Aillieo
* [`A Pencil Sketch Effect`](http://kylehalladay.com/blog/tutorial/2017/02/21/Pencil-Sketch-Effect.html) by Kyle Halladay
