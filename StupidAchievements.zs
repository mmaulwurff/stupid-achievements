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
    sa_Achievement.Name "You've got it!";
    sa_Achievement.Font "NewSmallFont";
  }

  String getName() const { return mName; }
  String getFont() const { return mFont; }

  private String mName;
  private String mFont;

  property Name: mName;
  property Font: mFont;

} // class sa_Achievement

class sa_Task abstract
{

  virtual
  void draw(int levelTime, double fracTic) {}

  bool isFinished(int levelTime) const
  {
    return levelTime > mBirthTime + LIFE_TIME;
  }

  void start()
  {
    mBirthTime = level.time;
  }

  protected
  void init(readonly<sa_Achievement> achievement)
  {
    mName = achievement.getName();
    mFont = Font.GetFont(achievement.getFont());

    mHorizontalPositionCvar = sa_Cvar.of("sa_horizontal_position");
    mVerticalPositionCvar   = sa_Cvar.of("sa_vertical_position");
  }

  protected String mName;
  protected Font   mFont;

  protected int    mBirthTime;

  protected sa_Cvar mHorizontalPositionCvar;
  protected sa_Cvar mVerticalPositionCvar;

  const LIFE_TIME = 35 * 3;

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
    Font f = mFont;

    String text = String.format("Achievement Unlocked\n%s", mName);
    int nLines = countLines(text);

    int textWidth  = f.stringWidth(text);
    int textHeight = f.getHeight() * nLines; // assuming no DTA_CellY in Screen.DrawText.

    int boxWidth  = MARGIN * 2 + textWidth;
    int boxHeight = MARGIN * 2 + textHeight;

    int borderWidth  = BORDER * 2 + boxWidth;
    int borderHeight = BORDER * 2 + boxHeight;

    int x, y;
    [x, y] = getXY(borderWidth, borderHeight, levelTime, fracTic);

    int textX   = x + MARGIN + BORDER;
    int textY   = y + MARGIN + BORDER;
    int boxX    = x + BORDER;
    int boxY    = y + BORDER;
    int borderX = x;
    int borderY = y;

    let tex = TexMan.checkForTexture("sa_gradb", TexMan.Type_Any);

    double alpha = getAlpha(levelTime, fracTic);

    // border
    Screen.DrawTexture( tex // not needed here, really, but something has to be here.
                      , NO_ANIMATION
                      , borderX
                      , borderY
                      , DTA_DestWidth,  borderWidth
                      , DTA_DestHeight, borderHeight
                      , DTA_FillColor,  0x222222
                      , DTA_Alpha,      alpha
                      );

    // box
    Screen.DrawTexture( tex
                      , NO_ANIMATION
                      , boxX
                      , boxY
                      , DTA_DestWidth,  boxWidth
                      , DTA_DestHeight, boxHeight
                      , DTA_FillColor,  0x2222AA
                      , DTA_AlphaChannel, true
                      , DTA_Alpha,      alpha
                      );

    // text
    Screen.DrawText( f
                   , Font.CR_White
                   , textX
                   , textY
                   , text
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

  const NO_ANIMATION = 0; // == false

  const MARGIN = 10;
  const BORDER =  1;

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

  protected static
  double getFractionIn(double time)
  {
    return clamp(time / ANIMATION_TIME, 0, 1);
  }

  protected static
  double getFractionOut(double time)
  {
    return clamp((time - (LIFE_TIME - ANIMATION_TIME)) / ANIMATION_TIME, 0, 1);
  }

  protected static
  int getValueBetween(int start, int target, double fraction)
  {
    return int(round(start * (1 - fraction) + target * fraction));
  }

  const ANIMATION_TIME = 35 / 4;
}

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

    if (time < ANIMATION_TIME)
    {
      // return slide in xy
      int    startX   = getStartX(width);
      double fraction = getFractionIn(time + fracTic);
      int    currentX = getValueBetween(startX, targetX, fraction);

      return currentX, targetY;
    }
    else if (time > LIFE_TIME - ANIMATION_TIME)
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

    if (time < ANIMATION_TIME)
    {
      // return slide in xy
      int    startY   = getStartY(height);
      double fraction = getFractionIn(time + fracTic);
      int    currentY = getValueBetween(startY, targetY, fraction);

      return targetX, currentY;
    }
    else if (time > LIFE_TIME - ANIMATION_TIME)
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

    if (time < ANIMATION_TIME)
    {
      return getFractionIn(time + fracTic);
    }
    else if (time > LIFE_TIME - ANIMATION_TIME)
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
