# Godot MPF Show Creator

The Godot MPF Show Creator is a tool for generating pinball light shows on machines running the Mission Pinball Framework.

# Installation and Setup

To use this tool, you will need an image of your playfield and the Godot editor version 4.2 or later (download from [godotengine.org](https://godotengine.org)). If your image is named `playfield.png` or `playfield.jpg` (all lowercase), that will save you a step down the road.

Download a ZIP of this repository from the [main repository page](https://github.com/missionpinball/mpf-gmc) by clicking the green **Code** button and *Download ZIP*. Extract the ZIP file in a convenient location.

> **Note**
Your playfield image should be between 600-1000 pixels wide, for ease of use. Smaller and it may be difficult to get precise positioning; larger and you'll spend a lot of time zooming and scrolling. It's also recommended that your playfield image height is less than the height of your monitor, so you can see the full image when previewing shows.


## Create your Project

Open the Godot editor and create a new Godot project.

> **Warning**
If you are using MPF and GMC, *do* ***not*** *use Show Creator in your main GMC project*. Create a separate project for Show Creator.

Open your new project and in the **Project** under Project Settings, turn on the *Advanced Settings* toggle in the upper right. Configure the following options:

**Display > Window > Size**
* Viewport Width: the width of your playfield image
* Viewport Height: the height of your playfield image
* Transparent: On

**Display > Window > Per Pixel Transparency**
* Allowed: On

**Rendering > Viewport**
* Transparent Background: On

Save the project and exit Godot.

## Add Necessary Files

Copy your playfield image to your project folder (where your *project.godot* file is).

> **Note** If your playfield image is named `playfield.png` or `playfield.jpg` (all lowercase) then the Show Creator will automatically find it and attach it to your scene.

Also in the project folder, create a new folder "*/addons*". Go to where you extracted the ZIP file and the */addons* folder there, and copy the *mpf-show-creator* folder into the */addons* folder in your project. To verify, your project root should have the file */addons/mpf-show-creator/plugin.cfg*. Re-open your project in Godot.

In the Godot editor, return to the *Project Settings* menu and click on the *Plugins* tab. You should see the plugin for **MPF Show Creator**, click the checkbox to enable it.

![Godot Plugin Window](docs/plugin-window.png)

## Initialize Your Scene

At the bottom panel of the Godot editor select the new tab called *MPF Show Creator* to open up the Show Creator panel.

![Show Creator Panel](docs/show-creator-panel.png)

Find the input box for *MPF Config File* and select the yaml file from your MPF project that includes the `lights:` definition for the lights in your machine.

After loading the yaml file, click on the "*Generate Show Creator Scene*" button to generate a scene file for building shows. The scene will be saved as "show_creator.tscn".

Your new scene should automatically open in the main editor view. If the scene *show_creator.tscn* does not open automatically, find the file in the *FileSystem* panel (lower left) and double-click it to open the scene in the main Godot editor window.

> **Note**
If you do not see your playfield image in the scene, you will need to manually attach it. The root node of the show creator scene is called `MPFShowCreator`, which you can see at the top of the *Scene* panel. Select it and in the *Inspector* panel, under *Sprite2D > Texture* select *Quick Load* and choose the image of your playfield. Your playfield image should now be aligned top-left with the Godot axis.

## Arrange Lights

The Show Creator generated special light nodes for each light it found in the MPF YAML config. You will see them all in the *Scene* panel (upper left) with a warning icon to indicate that they have not been positioned yet.

At the top of the scene editor window, select the crosshair cursor for the "Move Mode" tool (instead of the default "Select Mode"). Click on a light node in the *Scene* panel. In the main view you'll see an orange box with crosshairs highlighting the light. Drag the box to its appropriate position over the playfield image.

![Move Mode Tool](docs/move-icon.png)

Once a light has been moved, the warning icon will disappear. Proceed through all of the lights and position them across the playfield.

When all lights are positioned, save your project.

## Create Shapes for Animating

Now it's time to create shapes and animate them over the playfield. This project includes a number of pre-made shapes in the */show-creator/shapes* folder, or you're welcome to add your own shapes, images, or even videos.

Select the shape/image you want to use and drag it onto the playfield. Scale it to the size and starting position you'd like. Select the shape node in the *Scene* panel and look to the *Inspector* panel (upper right) and find the *Visibility* section. Click on the `Modulate` property to set the color of the shape.

### Single Color

You can quickly set a shape to be a single color with the *CanvasItem > Visibility > Modulate* property. This property overwrites the color values of the shape with white being transformed to the selected color and black not changing at all.

### Gradient

In your *FileSystem* panel, create a new resource of type `GradientTexture2D`. Choose a filename and save the gradient, then see the *Inspector Panel* to see the gradient.

Click on the horizontal *Gradient* section to expand the color selections, and select a point to set the color at that position. In the large square gradient above, you can use the white markers to adjust the angle and direction of the gradient.

You can drag your gradient resource from the *FileSystem* panel directly onto the playfield to use it as a rectangular shape.

## Create an Animation

For a nice tutorial on using animations in Godot, see the [Introduction to Animation Features](https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html) walkthrough. It's a good idea to read through this guide before proceeding.

Select the `AnimationPlayer` node in the *Scene* panel and the *Animation* panel will open at the bottom of the editor. Click on *Animation* and select *New*. Enter the name of the show you want to create and click OK.

The animation will default to be 1 second long, which you can change by entering the duration (in seconds) to the right of the clock icon on the timeline.

![Animation Panel](docs/animation-panel.png)

Set your shape(s) to their initial position and size, and create keyframes for those properties (i.e. if you are going to animate position, you will need position keyframes, and if you are animating size, you will also need size keyframes).

Some properties that you may want to animate:

* Transform > Position
* Transform > Rotation
* Transform > Scale
* Visibility > Modulate (to animate the color)

To create a keyframe, set the shape properties how you want them and in the *Inspector* panel, click on the key icon next to any property you want to animate.

*Note: The first time your add a keyframe to an animation, you will get a prompt. Select Bezier Curves only if you intend to do advanced easing between keyframes. Deselect* Create RESET Track(s) *as you won't need them for Show Creator.*

In the *Animation* panel, drag the blue timeline handle to the time of the next keyframe you want to create. Move your shape(s) to the desired position, and click on the key icon again.

Repeat this process for all shapes and properties you want to animate for the show. You can preview the animation at any time by pressing the Play icon in the top left of the *Animation* panel.

## Render Your Show

When your animation is ready, save your scene and return to the *MPF Show Creator* panel. Click on the *Refresh Animations* button to get the animations you just created (if the button doesn't work, make sure you've saved the scene).

On the right side of the *MPF Show Creator* panel, select the animation you wish to generate a show for and click on the orange *Generate Show* button.

A window will appear with the animation rendering, and after it finishes a file browser window will appear with the show saved as a MPF YAML file. Copy this file to your MPF project's */shows* folder.
