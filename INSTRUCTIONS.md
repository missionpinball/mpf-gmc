# GMC Setup and Overview

The Godot Media Controller is a plugin for the Godot game engine that provides integration with the Mission Pinball Framework for using Godot as the media engine on top of an MPF game.


## Installation

### 1. Download Godot

Visit https://godotengine.org to download and install the latest version of the Godot editor.

### 2. Create or Copy a Project

The fastest way to get started is to copy an existing sample project from the [MPF Examples](https://github.com/missionpinball/mpf-examples) repository. The **GMC Slides and Widgets** project is a good place to start, and you can then skip down to step 4.

If you want to create a project from scratch, open the Godot editor and create a new project in your MPF machine project folder. Open your new project in the editor.

### 3. Install the GMC Add-On

In the Godot Editor, go to the Godot Asset Library and search for the MPF GMC Plugin. Download and install the plugin, which will be added to the */addons/mpf-gmc* directory in your project folder.

Alternatively, you can clone the MPF GMC repository from https://github.com/missionpinball/mpf-gmc/ and copy or symlink the */addons/mpf-gmc* folder into your project's folder (also at */addons/mpf-gmc*).

The plugin provides the necessary framework to build MPF-responsive scenes in your project, but does not provide access to MPF data and communications.

**You must go to *Project Settings -> Globals* and select */addons/mpf-gmc/mpf_gmc.gd* as a Global and give it the name `MPF`.** Add and enable this global, then restart the Godot editor.

> [!CAUTION]
> It is critical that the Global has the name `MPF` in order for the GMC to function properly!


## Basic Usage

### Godot Terminology
In Godot, every component (text, video, colored rectangle, image, button) is a type of `Node`, and nodes are assembled together into `Scenes` and saved as *.tscn* files. GMC provides custom node types for MPF-specific uses, and you will make scenes to be the slides and widgets you need. You may first want to run through some basic Godot tutorials to get an understanding of how Godot works and how to build scenes. Anything you can create in a Godot scene can be used in a GMC slide or widget!

### The GMC Nodes
The GMC plugin provides a few components (nodes) that provide the foundation of running a game with GMC:
* `MPFWindow`: The base window that runs all the displays and slides. This is the entry point of GMC.
* `MPFDisplay`: A virtual display that contains slides. Your game may have one or more displays.
* `MPFSlide`: A slide (scene) containing any number of components that is rendered on a display
* `MPFWidget`: A widget (scene) containing any number of components that is added to a slide
* `MPFVariable`: A text component with dynamic content based on machine, player, or event variables

To start building your game in GMC, you will create scenes for your slides and use `slide_player` to play the slides based on triggering events.

### Heirarchy and Startup Flow
The GMC plugin comes with premade default scenes for Window, Display, and some core Slides (splash, attract, base, bonus). These can be found in the */addons/mpf-gmc/* folder. Any of these defaults can be overridden by creating scenes of the same name in your project.

> [!WARNING]
> It is not recommended to edit the default scenes in the */addons/mpf-gmc/* folder because they will be overwritten with every GMC update. Copy the scene file into your project */slides* folder and edit the copy. GMC will choose your project's file over a default file with the same name.

The entry point of GMC is a Godot scene called *window.tscn* with a root node of type `MPFWindow`. This node should have child nodes of type `MPFDisplay`, with one node for each distinct display you wish to use. Each display can have a name to be targeted for slides and widgets, and one display should have `is_default` enabled to be designated as the default display (for slides and widgets that don't specify a `display`). Each display will also have an `initial_slide` (an MPFSlide scene) that will be rendered at startup.

> [!NOTE]
> For multiple displays, set your project dimensions to be the maximum bounding box of all displays, and in your *window.tscn* create `MPFDisplay` nodes with the dimensions and positions that correspond to your monitors.

When GMC starts, it will open the window scene and load the initial slides into each display. The startup script will then open a BCP connection and wait for MPF to load (or optionally, spawn an MPF process itself). After connecting to MPF and initializing machine variables and configuration, MPF will move into attract mode and GMC will be ready to begin displaying slides.

### Creating and Playing Slides

Each slide is a Godot scene with a root node of `MPFSlide`. Slides can live in the */slides* folder in your project root, or in any */modes/<mode_name>/slides* folder in your MPF modes. Subfolders are allowed for further organization. The name of the scene file will be the name of the slide you reference in MPF configs.

To create a new slide, in the Godot Editor select *Create New... > Scene*, select a file name for the slide (e.g. *skillshot_overlay.tscn*), change the root node from `Node2D` to `MPFSlide`, and save the file into the */slides* folder or */modes/skillshot/slides* folder. The editor will then open the scene and you can add text, images, videos, colors, animations, shader effects, and anything else you'd like.

To play the slide, add a `slide_player` event to your mode configuration.

```
slide_player:
  mode_skillshot_started: skillshot_overlay
```

> [!TIP]
> The default action for the slide player is `play`, so it's not necessary to include `action: play` in the config (but you can if you'd like).

GMC slides support context tracking, which means that GMC knows that this slide is being triggered from the skillshot mode. Consequently, when the skillshot mode ends this slide will automatically be removed.

If you want to remove a slide before its triggering mode ends, you can manually remove the slide with the `action: remove` config:
```
slide_player:
  skillshot_failed:
    skillshot_overlay:
      action: remove
```

### Slide Stacks

Each display retains a "stack" of all the slides that are currently available. Whenever a slide is added or removed, the display will sort the stack with the highest priority slides on top. The lower slides will continue to receive updates, so you can freely remove slides without having to manually update the ones underneath.

Godot scenes support transparency, so it's possible to create "overlay" slides with transparent backgrounds. When these are on top of the stack, the lower-stacked slides will be visible below the higher ones.

By default, each slide is rendered with the priority of the mode that requested it. Slide priorities can be further adjusted with the `priority` config option, which will be added to (or subtracted from) the mode's priority to calculate the slide's effective priority.

```
  slide_player:
    mode_multiball_started: multiball_base_slide
    multiball_super_jackpot_lit:
      multiball_super_jackpot_slide:
        priority: 10
    multiball_super_jackpot_hit:
      multiball_super_jackpot_slide:
        action: remove
```

In the above example, the *multiball_base_slide* will play on the display when the multiball mode starts, and the *multiball_super_jackpot_slide* will play on top of it when the jackpot is lit (because its priority will be +10 the priority of the *multiball_base_slide*). After the jackpot is hit, the *multiball_super_jackpot_slide* will be removed and the underlying *multiball_base_slide* will be visible again.

### Displaying Variables on Slides and Widgets

#### Basic Variable Usage
The `MPFVariable` class allows you to render dynamic content in slides and widgets, including player variables (current player or a specific player number), machine variables, and event arguments.

To add a variable value to a slide or widget, open the slide or widget in the Editor and add a new node of type `MPFVariable`. You can then customize the variable in the Inspector:
* **variable_name**: The name of the player variable, machine variable, or event argument
* **comma_separate**: If checked, the number value will be comma-separated into thousands
* **min_digits**: If greater than zero, the number will be left-padded with zeros up to this number of digits
* **initialize_empty**: If checked, this text node will be empty until an event update provides a value

The **template** configuration option allows you to embed the variable value within a larger text string. For example, having a variable for the player number will initially only render the number (e.g. "1"), but by adding a template with `%s` as a variable placeholder (e.g. `Player %s`), the template will be rendered with the injected variable value (e.g. "Player 1").

> [!NOTE]
> Only one variable is allowed per `MPFVariable` node. For complex strings involving multiple variables you can use a custom method on the slide, or use an `MPFRichVariable` node.

#### Event Arguments
Beyond player and machine variables, event arguments can also be used in `MPFVariable` nodes. All arguments from the triggering event are automatically included, and additional arguments can be provided in the `tokens:` configuration.

In the following example, the event *bonus_entry_one* includes an argument *score* with the value of the bonus score. The slide *bonus_slide.tscn* includes one MPFVariable with Event Args "score" and another with Event Args "title". The below code will update the slide with **both** the "score" value from the original *bonus_entry_one* event and the "title" value from the slide_player configuration:

```
slide_player:
  bonus_entry_one:
    bonus_slide:
      action: update
      tokens:
        title: "Drop Bank Completions"
```

### Custom Behavior on Slides and Widgets

Just like MPF modes can have advanced behavior through custom code, GMC slides and widgets can have advanced behavior through methods on the root node. To build a slide with custom behavior, create a new scene and give the root node a custom script that inherits from `MPFSlide` and has a public method.

```
# /slides/wacky_score.tscn
extends MPFSlide

func rotate_score(_kwargs):
  $AnimationPlayer.play("rotate")

func show_hint(kwargs):
  $Hint.text = kwargs.hint_text
  $Hint.visible = true
```

In this example, the scene includes an AnimationPlayer with an animation called "rotate" that will rotate the player's score in a circle. That animation is called in a public method `rotate_score`, which can be triggered via MPF with the `action: method` configuration. It also includes a child text node called Hint which can be triggered to display some text with the `show_hint` method.

```
slide_player:
  mode_wacky_score_started:
    wacky_score:
      action: play
  score_jackpot_hit:
    wacky_score:
      action: method
      method: rotate_score
  timer_wacky_score_hint_complete:
    wacky_score:
      action: method
      method: show_hint
      tokens:
        hint_text: "Hit the Spinner for Wacky Score!"
```

When the *score_jackpot_hit* event occurs, the slide player will call the `rotate_score()` method on the *wacky_score* slide and trigger the animation. When the hint timer completes with the *timer_wacky_score_hint_complete* event, the slide player will call the `show_hint()` method on the slide and pass in all of the event arguments as a dictionary, which the `show_hint()` method can access to render the `hint_text` on the slide.
