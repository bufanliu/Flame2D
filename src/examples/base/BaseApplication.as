

package examples.base  {
    import Flame2D.core.data.Consts;
    import Flame2D.core.data.Subscriber;
    import Flame2D.core.events.EventArgs;
    import Flame2D.core.events.RenderQueueEventArgs;
    import Flame2D.core.events.WindowEventArgs;
    import Flame2D.core.fonts.FlameSystemFont;
    import Flame2D.core.properties.FlamePropertyHelper;
    import Flame2D.core.system.FlameEventManager;
    import Flame2D.core.system.FlameFont;
    import Flame2D.core.system.FlameFontManager;
    import Flame2D.core.system.FlameImageSetManager;
    import Flame2D.core.system.FlameMouseCursor;
    import Flame2D.core.system.FlameRenderingSurface;
    import Flame2D.core.system.FlameResourceProvider;
    import Flame2D.core.system.FlameSchemeManager;
    import Flame2D.core.system.FlameSystem;
    import Flame2D.core.system.FlameWindow;
    import Flame2D.core.system.FlameWindowManager;
    import Flame2D.core.system.FlameWindowRendererManager;
    import Flame2D.core.utils.ColourRect;
    import Flame2D.core.utils.Misc;
    import Flame2D.core.utils.Rect;
    import Flame2D.core.utils.Size;
    import Flame2D.core.utils.TextUtils;
    import Flame2D.core.utils.UDim;
    import Flame2D.core.utils.UVector2;
    import Flame2D.core.utils.Vector2;
    import Flame2D.core.utils.Vector3;
    import Flame2D.elements.button.FlameCheckbox;
    import Flame2D.elements.combobox.FlameCombobox;
    import Flame2D.elements.window.FlameFrameWindow;
    import Flame2D.elements.window.FlameGUISheet;
    import Flame2D.loaders.TextFileLoader;
    import Flame2D.renderer.FlameGeometryBuffer;
    import Flame2D.renderer.FlameRenderer;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display3D.Context3D;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.ui.Keyboard;
    import flash.ui.Mouse;
    import flash.utils.getTimer;
    
    public class BaseApplication extends Sprite
    {
        private var context3D:Context3D = null;
        private var stage3D:Stage3D = null;
        private var stageWidth : uint = 800;
        private var stageHeight : uint = 600;
        private var viewport:Rectangle = new Rectangle();
        
        
        //async loader for schemes
        private var schemesLoaded:uint = 0;
        private var totalSchemes:uint = 3;
        
        protected var appInitialized:Boolean = false;
        
        //logo
        private var d_logo_geometry:FlameGeometryBuffer = null;
        private var d_logo_rot:Number = 0;

        // fps
        private var d_fps_geometry:FlameGeometryBuffer = null;
        private var fpsLast:uint = getTimer();
        private var fpsTicks:uint = 0;
        private var d_fps_textbuff:String = "";
        //private var fpsTf:TextField;
        
        //for efficiency
        private var d_system:FlameSystem = null;
        
        public function BaseApplication()
        {
            if (stage != null) 
                init();
            else 
                addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init():void
        {
            if (hasEventListener(Event.ADDED_TO_STAGE))
                removeEventListener(Event.ADDED_TO_STAGE, init);
            
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            // and request a context3D from Stage3d
            stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
            stage.stage3Ds[0].requestContext3D();

        }

        private function onContext3DCreate(event:Event):void
        {
            // Obtain the current context
            stage3D = event.target as Stage3D;					
            context3D = stage3D.context3D; 	
            
            if (context3D == null) 
            {
                // Currently no 3d context is available (error!)
                return;
            }
            
            // Disabling error checking will drastically improve performance.
            // If set to true, Flash sends helpful error messages regarding
            // AGAL compilation errors, uninitialized program constants, etc.
            context3D.enableErrorChecking = true;
            
            
            // The 3d back buffer size is in pixels
            stageWidth = stage.stageWidth;
            stageHeight = stage.stageHeight;
            viewport = new Rectangle(0,0, stageWidth, stageHeight);
            
            context3D.configureBackBuffer(stageWidth, stageHeight, 0, true);
            
            initFlame();
            initListeners();
        }
        
        
        
        private function initFlame():void
        {
            //Create flame viewport
            //FlameSystem.getSingleton().initialize();
            FlameSystem.getSingleton().getRenderer().initialize(stage, stage3D, context3D);
            
            //load scheme is async
            FlameSchemeManager.getSingleton().create("WindowsLook.scheme", onSchemeLoaded);
            FlameSchemeManager.getSingleton().create("TaharezLook.scheme", onSchemeLoaded);
            FlameSchemeManager.getSingleton().create("VanillaSkin.scheme", onSchemeLoaded);

        }
        
        private function onSchemeLoaded():void
        {
            schemesLoaded ++;
            if(schemesLoaded == totalSchemes)
            {
                postInitFlame();
            }
        }
        
        private function postInitFlame():void
        {
            FlameEventManager.getSingleton().initialize(stage);
            d_system = FlameSystem.getSingleton();
            
            var font:FlameFont = FlameFontManager.getSingleton().createSystemFont("Times New Roman", 14);
            FlameSystem.getSingleton().setDefaultFont(font);


            FlameImageSetManager.getSingleton().createFromImageFile("BackgroundImage", "GPN-2000-001437.png", "", onBackgroundImageLoaded);
            
            // set tooltip styles (by default there is none)
            FlameSystem.getSingleton().setDefaultTooltipForType("TaharezLook/Tooltip");
        }
        
        private function onBackgroundImageLoaded(tag:Object):void
        {
            // setup for logo
            FlameImageSetManager.getSingleton().createFromImageFile("cegui_logo", "logo.png", "", onLogoLoaded);
        }
        
        private function onLogoLoaded(tag:Object):void
        {
            const scrn:Rect = new Rect(0,0, 
                FlameSystem.getSingleton().getRenderer().getDisplaySize().d_width,
                FlameSystem.getSingleton().getRenderer().getDisplaySize().d_height
                );
            
            d_fps_geometry = FlameSystem.getSingleton().getRenderer().createGeometryBuffer();
            
            
            d_logo_geometry = FlameSystem.getSingleton().getRenderer().createGeometryBuffer();
            d_logo_geometry.setClippingRegion(scrn);
            d_logo_geometry.setPivot(new Vector3(50, 34.75, 0));
            d_logo_geometry.setTranslation(new Vector3(10, 520, 0));
            FlameImageSetManager.getSingleton().getImageSet("cegui_logo").
                getImage("full_image").draw2(d_logo_geometry, new Rect(0, 0, 100, 69.5), null, new ColourRect());
            
            // clearing this queue actually makes sure it's created(!)
            FlameSystem.getSingleton().getRenderer().getDefaultRenderingRoot().clearGeometry(Consts.RenderQueueID_RQ_OVERLAY);
            // subscribe handler to render overlay items
            FlameSystem.getSingleton().getRenderer().getDefaultRenderingRoot().
                subscribeEvent(FlameRenderingSurface.EventRenderQueueStarted,
                    new Subscriber(overlayHandler, this), FlameRenderingSurface.EventNamespace);

            FlameImageSetManager.getSingleton().create("DriveIcons", "DriveIcons.imageset", "", onDriveIconsLoaded);
        }
        
        private function overlayHandler(args:EventArgs):Boolean
        {
            if (RenderQueueEventArgs(args).queueID != Consts.RenderQueueID_RQ_OVERLAY)
                return false;
            
            // render FPS:
            var fnt:FlameFont = FlameSystem.getSingleton().getDefaultFont();
            if (fnt)
            {
                d_fps_geometry.reset();
                fnt.drawText(d_fps_geometry, d_fps_textbuff, new Vector2(0, 0), null, new ColourRect);
                d_fps_geometry.draw();
            }
            
            d_logo_geometry.draw();
            
            return true;
        }

        private function onDriveIconsLoaded(tag:Object):void
        {
            initApp();
        }


        private function initListeners() : void {
            //stage.addEventListener(Event.RESIZE, onResize);
            //stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            //onResize(null);
        }
        
        
        
        private function onEnterFrame(event : Event) : void 
        {
            if(! d_system) return;

            context3D.clear(0,0,0,0);
            
            //update flame and render
            d_system.renderGUI();
            
            // update the FPS display
            fpsTicks++;
            var now:uint = getTimer();
            var delta:uint = now - fpsLast;
            // only update the display once a second
            if (delta >= 1000) 
            {
                var fps:Number = fpsTicks / delta * 1000;
                //fpsTf.text = fps.toFixed(1) + " fps";
                d_fps_textbuff = fps.toFixed(1)  + " fps";
                fpsTicks = 0;
                fpsLast = now;
            }
            
            //draw logo
            if(d_logo_geometry)
            {
                d_logo_geometry.setRotation(new Vector3(d_logo_rot, 0, 0));
                d_logo_rot = now/10000;
            }
            
            context3D.present();
        }
        
        
        private function onResize(event: Event) : void
        {
            if(stageWidth != stage.stageWidth || stageHeight != stage.stageHeight)
            {
                context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, 1);
//                FlameSystem.getSingleton().getRenderer().onResize();
                FlameSystem.getSingleton().notifyDisplaySizeChanged(new Size(stage.stageWidth, stage.stageHeight));
            }    
        }
        
        //should be overrided
        protected function initApp():void
        {
            throw new Error("Please create your own app.");
        }
    }
}
