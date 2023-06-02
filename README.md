# Floating Healthbars

Adds customizable healthbars that are displayed above enemies when you aim at them.
You can customize the style of the healthbar, the direction it fills in, the size (including dynamic scaling based on text or enemy HP) and more in the mod options.

## Creating your own designs

You can use the included `template.png` file to make your own healthbar design to use with the mod. The middle part of the image is what's used as the healthbar and will be stretched to the needed size. Top, middle and bottom row are background, healthbar and foreground respectively. The left and right sides are added to the left and right side of the healthbar. The space in between the squares is safe space to guarantee the UV mapping does not blur edges, make sure to horizontally extend your healthbar design a few pixels outside of the squares if you dont want blurry borders.

Once you're done, export the image as dds file and place it in `mods/saves/floating_healthbars/` to make the mod find it. Avoid placing it in the `assets` folder of the mod as you will lose any files you add there when the mod receives an update.
