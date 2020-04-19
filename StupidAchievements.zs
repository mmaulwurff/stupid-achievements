class sa_Achiever : EventHandler
{

  static
  void achieve(String achievementClass)
  {
    let me = sa_Achiever(EventHandler.find("sa_Achiever"));
    Class<sa_Achievement> c = achievementClass;

    if (c == NULL)
    {
      Console.Printf("%s is not an achievement class!", achievementClass);
      return;
    }

    let achievement   = getDefaultByType(c);
    int animationType = me.mAnimationTypeCvar.getInt();

    switch (animationType)
    {
    case 0:  me.mTasks.push(sa_SlideVerticallyTask  .of(achievement)); break;
    case 1:  me.mTasks.push(sa_SlideHorizontallyTask.of(achievement)); break;
    case 2:  me.mTasks.push(sa_FadeInOutTask        .of(achievement)); break;
    default: me.mTasks.push(sa_NoAnimationTask      .of(achievement)); break;
    }

    if (me.mTasks.size() == 1)
    {
      me.mTasks[0].start();
    }
  }

  override
  void OnRegister()
  {
    mAnimationTypeCvar = sa_Cvar.of("sa_animation_type");
  }

  override
  void WorldTick()
  {
    let task = getCurrentTask();
    int time = level.time;

    if (task && task.isFinished(time))
    {
      mTasks.delete(0);

      let nextTask = getCurrentTask();
      if (nextTask)
      {
        nextTask.start();
      }
    }
  }

  override
  void RenderOverlay(RenderEvent event)
  {
    let task = getCurrentTask();
    int time = level.time;

    if (task && !task.isFinished(time))
    {
      task.draw(time, event.fracTic);
    }
  }

  private
  sa_Task getCurrentTask() const
  {
    return(mTasks.size() == 0)
      ? NULL
      : mTasks[0];
  }

  private Array<sa_Task> mTasks;
  private sa_Cvar mAnimationTypeCvar;

} // class sa_Achiever

class sa_Achievement : Actor abstract
{

  Default
  {
    sa_Achievement.title "Achievement Unlocked"; // General title for achievements.
    sa_Achievement.name  "You've got it!";       // Specific name for this achievement.

    // Overall duration of achievement notification, including animation.
    // In tics, 35 tics is a second.
    sa_Achievement.lifetime      35 * 3;
    // Duration of animation of achievement notification.
    // Notification can be not animated, see sa_animation_type Cvar.
    // If the notification is animated, there are two animations: appearing and disappearing.
    // In tics, 35 tics is a second.
    sa_Achievement.animationTime 35 / 4;

    // Background alpha map texture. Default: gradient to background, top to bottom.
    // Must exist.
    // Will be mercilessly scaled to box width and height.
    sa_Achievement.texture     "sa_gradb";
    sa_Achievement.fontName    "NewSmallFont";
    sa_Achievement.borderColor 0x222222; // Border and background color. RGB: 0xRRGGBB.
    sa_Achievement.boxColor    0x2222AA; // Foreground color. RGB: 0xRRGGBB.
    sa_Achievement.textColor   Font.CR_White; // Text color. See Font struct for available colors.

    sa_Achievement.margin 10; // px, space between text and border.
    sa_Achievement.border  1; // px, border width.
  }

  String title;
  String name;

  int lifetime;
  int animationTime;

  String fontName;
  String texture;
  int    borderColor;
  int    boxColor;
  int    textColor;

  int margin;
  int border;

  property title         : title;
  property name          : name;

  property lifetime      : lifetime;
  property animationTime : animationTime;

  property fontName      : fontName;
  property texture       : texture;
  property borderColor   : borderColor;
  property boxColor      : boxColor;
  property textColor     : textColor;

  property margin        : margin;
  property border        : border;

} // class sa_Achievement

class sa_Task abstract
{

  virtual
  void draw(int levelTime, double fracTic) {}

  bool isFinished(int levelTime) const
  {
    return levelTime > mBirthTime + mLifetime;
  }

  void start()
  {
    mBirthTime = level.time;
  }

  protected
  void init(readonly<sa_Achievement> achievement)
  {
    mText          = String.format("%s\n%s", achievement.title, achievement.name);
    mNLines        = countLines(mText);

    mLifetime      = achievement.lifetime;
    mAnimationTime = achievement.animationTime;

    mFont          = Font.GetFont(achievement.fontName);
    mTexture       = TexMan.checkForTexture(achievement.texture, TexMan.Type_Any);
    mBorderColor   = achievement.borderColor;
    mBoxColor      = achievement.boxColor;
    mTextColor     = achievement.textColor;

    mMargin        = achievement.margin;
    mBorder        = achievement.border;

    mHorizontalPositionCvar = sa_Cvar.of("sa_horizontal_position");
    mVerticalPositionCvar   = sa_Cvar.of("sa_vertical_position");
  }

  protected String    mText;
  protected int       mNLines;
  protected int       mLifetime;
  protected int       mAnimationTime;
  protected Font      mFont;
  protected TextureID mTexture;
  protected int       mBorderColor;
  protected int       mBoxColor;
  protected int       mTextColor;
  protected int       mMargin;
  protected int       mBorder;

  protected int mBirthTime;

  protected sa_Cvar mHorizontalPositionCvar;
  protected sa_Cvar mVerticalPositionCvar;

  private
  int countLines(String s)
  {
    int nBytes = s.length();
    int nLines = 1;
    for (int i = 0; i < nBytes; ++i)
    {
      nLines += (s.byteAt(i) == 10);
    }
    return nLines;
  }

} // class sa_Task abstract

class sa_NoAnimationTask : sa_Task
{

  static
  sa_Task of(readonly<sa_Achievement> achievement)
  {
    let result = new("sa_NoAnimationTask");

    result.init(achievement);

    return result;
  }

  override
  void draw(int levelTime, double fracTic)
  {
    int textWidth  = mFont.stringWidth(mText);
    int textHeight = mFont.getHeight() * mNLines; // assuming no DTA_CellY in Screen.DrawText.

    int boxWidth  = mMargin * 2 + textWidth;
    int boxHeight = mMargin * 2 + textHeight;

    int borderWidth  = mBorder * 2 + boxWidth;
    int borderHeight = mBorder * 2 + boxHeight;

    int x, y;
    [x, y] = getXY(borderWidth, borderHeight, levelTime, fracTic);

    int textX   = x + mMargin + mBorder;
    int textY   = y + mMargin + mBorder;
    int boxX    = x + mBorder;
    int boxY    = y + mBorder;
    int borderX = x;
    int borderY = y;

    double alpha = getAlpha(levelTime, fracTic);

    // border
    Screen.DrawTexture( mTexture // not needed here, really, but something has to be here.
                      , NO_ANIMATION
                      , borderX
                      , borderY
                      , DTA_DestWidth  , borderWidth
                      , DTA_DestHeight , borderHeight
                      , DTA_FillColor  , mBorderColor
                      , DTA_Alpha      , alpha
                      );

    // box
    Screen.DrawTexture( mTexture
                      , NO_ANIMATION
                      , boxX
                      , boxY
                      , DTA_DestWidth    , boxWidth
                      , DTA_DestHeight   , boxHeight
                      , DTA_FillColor    , mBoxColor
                      , DTA_AlphaChannel , true
                      , DTA_Alpha        , alpha
                      );

    // text
    Screen.DrawText( mFont
                   , mTextColor
                   , textX
                   , textY
                   , mText
                   , DTA_Alpha, alpha
                   );
  }

  enum HorizontalPosition
  {
    HPOS_LEFT,
    HPOS_RIGHT,
  }

  enum VerticalPosition
  {
    VPOS_TOP,
    VPOS_BOTTOM,
  }

  protected virtual
  double getAlpha(int levelTime, double fracTic)
  {
    return 1;
  }

  protected virtual
  int, int getXY(int width, int height, int levelTime, double fracTic)
  {
    int horizontalPosition = mHorizontalPositionCvar.getInt();
    int verticalPosition   = mVerticalPositionCvar.getInt();
    int x = 0;
    int y = 0;

    switch (horizontalPosition)
    {
    case HPOS_LEFT:  x = 0; break;
    case HPOS_RIGHT: x = Screen.getWidth() - width; break;
    }

    switch (verticalPosition)
    {
    case VPOS_TOP:    y = 0; break;
    case VPOS_BOTTOM: y = Screen.getHeight() - height; break;
    }

    return x, y;
  }

  const NO_ANIMATION = 0; // == false

} // class sa_NoAnimationTask

class sa_AnimationTask : sa_NoAnimationTask abstract
{
  protected
  int getStartX(int width)
  {
    int horizontalPosition = mHorizontalPositionCvar.getInt();
    switch (horizontalPosition)
    {
    case HPOS_LEFT:  return -width;
    case HPOS_RIGHT: return Screen.getWidth();

    default: Console.printf("unknown horizontal position"); return 0;
    }
  }

  protected
  int getStartY(int height)
  {
    int verticalPosition = mVerticalPositionCvar.getInt();
    switch (verticalPosition)
    {
    case VPOS_TOP:  return -height;
    case VPOS_BOTTOM: return Screen.getHeight();

    default: Console.printf("unknown vertical position"); return 0;
    }
  }

  protected
  double getFractionIn(double time)
  {
    return clamp(time / mAnimationTime, 0, 1);
  }

  protected
  double getFractionOut(double time)
  {
    return clamp((time - (mLifetime - mAnimationTime)) / mAnimationTime, 0, 1);
  }

  protected static
  int getValueBetween(int start, int target, double fraction)
  {
    return int(round(start * (1 - fraction) + target * fraction));
  }

} // class sa_AnimationTask

class sa_SlideHorizontallyTask : sa_AnimationTask
{

  static
  sa_SlideHorizontallyTask of(readonly<sa_Achievement> achievement)
  {
    let result = new("sa_SlideHorizontallyTask");
    result.init(achievement);
    return result;
  }

  override
  int, int getXY(int width, int height, int levelTime, double fracTic)
  {
    int time = levelTime - mBirthTime;

    int targetX, targetY;
    [targetX, targetY] = super.getXY(width, height, levelTime, fracTic);

    if (time < mAnimationTime)
    {
      // return slide in xy
      int    startX   = getStartX(width);
      double fraction = getFractionIn(time + fracTic);
      int    currentX = getValueBetween(startX, targetX, fraction);

      return currentX, targetY;
    }
    else if (time > mLifetime - mAnimationTime)
    {
      // return slide out xy
      int    startX   = getStartX(width);
      double fraction = getFractionOut(time + fracTic);
      int    currentX = getValueBetween(targetX, startX, fraction);

      return currentX, targetY;
    }
    else
    {
      // return stay in place xy:
      return targetX, targetY;
    }
  }

} // class sa_SlideHorizontallyTask

class sa_SlideVerticallyTask : sa_AnimationTask
{

  static
  sa_SlideVerticallyTask of(readonly<sa_Achievement> achievement)
  {
    let result = new("sa_SlideVerticallyTask");
    result.init(achievement);
    return result;
  }

  override
  int, int getXY(int width, int height, int levelTime, double fracTic)
  {
    int time = levelTime - mBirthTime;

    int targetX, targetY;
    [targetX, targetY] = super.getXY(width, height, levelTime, fracTic);

    if (time < mAnimationTime)
    {
      // return slide in xy
      int    startY   = getStartY(height);
      double fraction = getFractionIn(time + fracTic);
      int    currentY = getValueBetween(startY, targetY, fraction);

      return targetX, currentY;
    }
    else if (time > mLifetime - mAnimationTime)
    {
      // return slide out xy
      int    startY   = getStartY(height);
      double fraction = getFractionOut(time + fracTic);
      int    currentY = getValueBetween(targetY, startY, fraction);

      return targetX, currentY;
    }
    else
    {
      // return stay in place xy:
      return targetX, targetY;
    }
  }

} // class sa_SlideVerticallyTask

class sa_FadeInOutTask : sa_AnimationTask
{

  static
  sa_FadeInOutTask of(readonly<sa_Achievement> achievement)
  {
    let result = new("sa_FadeInOutTask");
    result.init(achievement);
    return result;
  }

  override
  double getAlpha(int levelTime, double fracTic)
  {
    int time = levelTime - mBirthTime;

    if (time < mAnimationTime)
    {
      return getFractionIn(time + fracTic);
    }
    else if (time > mLifetime - mAnimationTime)
    {
      return 1 - getFractionOut(time + fracTic);
    }
    else
    {
      return super.getAlpha(levelTime, fracTic);
    }
  }
} // class sa_FadeInOutTask

/**
 * This class provides access to a user or server Cvar.
 *
 * Accessing Cvars through this class is faster because calling Cvar.GetCvar()
 * is costly. This class caches the result of Cvar.GetCvar() and handles
 * loading a savegame.
 */
class sa_Cvar
{

  static
  sa_Cvar of(String name)
  {
    let result = new("sa_Cvar");
    result._name = name;
    return result;
  }

  bool   isDefined() { load(); return (_cvar != NULL);   }

  String getString() { load(); return _cvar.GetString(); }
  bool   getBool()   { load(); return _cvar.GetInt();    }
  int    getInt()    { load(); return _cvar.GetInt();    }
  double getFloat()  { load(); return _cvar.GetFloat();  }

// private: ////////////////////////////////////////////////////////////////////

  private
  void load()
  {
    if (_cvar == NULL)
    {
      _cvar = Cvar.GetCvar(_name, players[consolePlayer]);

      if (_cvar == NULL)
      {
        Console.Printf("Cvar %s not found.", _name);
      }
    }
  }

  private String          _name;
  private transient Cvar  _cvar;

} // class tt_Cvar
