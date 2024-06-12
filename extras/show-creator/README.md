# Godot MPF Show Creator

The Godot MPF Show Creator is a tool for generating pinball light shows on machines running the Mission Pinball Framework.

# Installation and Setup

To use this tool, you will need an image of your playfield and the Godot 4 editor.

## Create your Project

Create a new Godot project (do *not* use your main GMC project) and under Project Settings, turn on the *Advanced Settings* toggle. Configure the following options:

**Display > Window**
* Viewport Width: the width of your playfield image
* Viewport Height: the height of your playfield image
* Transparent: On

**Display > Per Pixel Transparency**
* Allowed: On

**Rendering > Viewport**
* Transparent Background: On

Save and exit the project. Finally, copy this folder (*/show-creator*) into your project folder, and then re-open your project in Godot.

## Create your Scene

You should see an empty project and the *Scene* tab has buttons for Create Root Node. Select *+ Other Node* and search for `MPFShowCreator` and select that as your root node.

In the *Scene* panel, add a new node of type `AnimationPlayer` and then select the `MPFShowCreator` root node.

In the *Inspector* panel, under *Sprite2D > Texture* select *Quick Load* and choose the image of your playfield. Under *Sprite2D > Offset* un-check the *Centered* option. Your playfield image should now be aligned top-left with the Godot axis.

At the top of the *Inspector* panel, under *Animation Player* click on *Assign* and select the `AnimationPlayer` node you added to the scene. Then set the following options to your preference:

* FPS: The frame rate at which to render the show
* Strip Unchanged Lights: If enabled, lights will only be added in show steps if they change. If disabled, every light will be defined on every step even if it doesn't change.
* Strip Empty Times: If enabled, time codes will not be in the show if they have no light changes. If disabled, every time code will be defined even if it has no lights.
* Use Alpha: If enabled, color values will include an alpha (opacity) value. If disabled, color values will only be RGB.

Save your scene as whatever name you'd like (it will be the only scene in the project).

## Add Lights

With the `MPFShowCreator` node selected, add a new node to your scene of type `MPFShowLight`. Give this node the name of a light in your MPF config (e.g. `l_left_ramp`) and drag it to the appropriate position over your playfield image.

Right click on the light node and select *Duplicate* (or press Cmd+D/Ctrl+D). Give the duplicated node the name of another light and drag it to the appropriate position.

Repeat this process for all of the lights on your playfield. It's tedious, so save often.

## Create Shapes for Animating

Now it's time to create shapes and animate them over the playfield. This project includes a number of pre-made shapes in the */show-creator/shapes* folder, or you're welcome to add your own shapes or images.

Select the shape/image you want to use and drag it onto the playfield. Scale it to the size and starting position, and then select the shape node in the *Scene* panel to set the color.

### Single Color

You can quickly set a shape to be a single color with the *CanvasItem > Visibility > Modulate* property. This property overwrites the color values of the shape with white being transformed to the selected color and black not changing at all.

### Gradient

In your *FileSystem* panel, create a new resource of type `GradientTexture2D`. Choose a filename and save the gradient, then see the *Inspector Panel* to see the gradient.

Click on the horizontal *Gradient* section to expand the color selections, and select a point to set the color at that position. In the large square gradient above, you can use the white markers to adjust the angle and direction of the gradient.

You can drag your gradient resource from the *FileSystem* panel directly onto the playfield to use it as a rectangular shape.

## Create an Animation

Select the `AnimationPlayer` node and in the *Animation* panel at the bottom, click on *Animation* and select *New*. Enter the name of the show you want to create and click OK.

The animation will default to be 1 second long, which you can change by entering the duration (in seconds) to the right of the clock icon on the timeline.

Set your shape(s) to their initial position and size, and create keyframes for those properties (i.e. if you are going to animate position, you will need position keyframes, and if you are animating size, you will also need size keyframes).

Some properties that you may want to animate:

* Transform > Position
* Transform > Rotation
* Transform > Scale
* Visibility > Modulate

To create a keyframe, set the shape where you want it to be and in the *Inspector* panel, click on the lock icon next to any property you want to animate.

*Note: The first time your add a keyframe to an animation, you will get a prompt. Select Bezier Curves if you want to do advanced easing between frames. Deselect* Create RESET Track(s) *as you won't need them for Show Creator.*

In the *Animation* panel, drag the blue timeline handle to the time of the next keyframe you want to create. Move your shape(s) to the desired position, and click on the lock icon again.

Repeat this process for all shapes and properties you want to animate for the show. You can preview the animation at any time by pressing the Play icon in the top left of the *Animation* panel.

## Render Your Show

When your animation is ready, select the `MPFShowCreator` root node and in the *Inspector* panel, type in the name of the animation you want to render to a show.

Play the Scene in Godot. If you see a prompt that no main scene is defined, choose "Select Current".

A window will appear with the animation rendering, and after it finishes a file browser window will appear with the show saved as a MPF YAML file. Copy this file to your MPF project's */shows* folder.