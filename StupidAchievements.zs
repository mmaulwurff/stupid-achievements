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

    let achievement = getDefaultByType(c);
    me.mTasks.push(sa_NoAnimationTask.of(achievement));

    if (me.mTasks.size() == 1)
    {
      me.getCurrentTask().start();
    }
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
    [x, y] = getXY(borderWidth, borderHeight);

    int textX   = x + MARGIN + BORDER;
    int textY   = y + MARGIN + BORDER;
    int boxX    = x + BORDER;
    int boxY    = y + BORDER;
    int borderX = x;
    int borderY = y;

    let tex = TexMan.checkForTexture("sa_gradb", TexMan.Type_Any);

    // border
    Screen.DrawTexture( tex // not needed here, really, but something has to be here.
                      , NO_ANIMATION
                      , borderX
                      , borderY
                      , DTA_DestWidth,  borderWidth
                      , DTA_DestHeight, borderHeight
                      , DTA_FillColor,  0x222222
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
                      );

    // text
    Screen.DrawText( f
                   , Font.CR_White
                   , textX
                   , textY
                   , text
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

  private
  int, int getXY(int width, int height)
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
  const BORDER =  2;

} // class sa_NoAnimationTask

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
