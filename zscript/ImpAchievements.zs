/* Copyright Alexander 'm8f' Kromm (mmaulwurff@gmail.com) 2020
 *
 * This file is a part of Typist.pk3.
 *
 * Typist.pk3 is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * Typist.pk3 is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * Typist.pk3.  If not, see <https://www.gnu.org/licenses/>.
 */

class ia_EventHandler : EventHandler
{

  override
  void worldLoaded(WorldEvent event)
  {
    String className = "Z_SpriteShadow";
    class<Actor> c = className;
    bool isSpriteShadowLoaded = (c != NULL);

    if (isSpriteShadowLoaded && isImpsPresent())
    {
      sa_Achiever.achieve("ia_Shadow");
    }

    mIsImpDied = false;
  }

  override
  void worldUnloaded(WorldEvent event)
  {
    if (isImpsPresent() && !mIsImpDied)
    {
      sa_Achiever.achieve("ia_Friend");
    }
  }

  override
  void worldThingDied(WorldEvent event)
  {
    if (isImp(event.thing))
    {
      sa_Achiever.achieve("ia_OneKill");
      sa_Achiever.achieve("ia_TenKills");
      sa_Achiever.achieve("ia_100Kills");
      sa_Achiever.achieve("ia_666Kills");

      if (event.thing.health < -200)
      {
        sa_Achiever.achieve("ia_Overkill");
      }

      mIsImpDied = true;
    }
  }

  override
  void worldThingDamaged(WorldEvent event)
  {
    if (!isImp(event.thing)) return;

    if (event.damagetype == "Telefrag")
    {
      sa_Achiever.achieve("ia_Telefrag");
    }
    else if (event.damagetype == "Melee")
    {
      sa_Achiever.achieve("ia_Melee");
    }
  }

  private
  bool isImp(Actor a)
  {
    bool isReplacingImp = ("DoomImp" == Actor.getReplacee(a.getClass()));
    bool isBasedOnImp   = (a is "DoomImp");
    return (isReplacingImp || isBasedOnImp);
  }

  private
  bool isImpsPresent()
  {
    let i = ThinkerIterator.create();
    Actor a;
    while (a = Actor(i.next()))
    {
      if (isImp(a)) return true;
    }
    return false;
  }

  private bool mIsImpDied;

} // class ia_EventHandler

class ia_OneKill : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Initiate";
    sa_Achievement.description "Kill one imp";
    sa_Achievement.borderColor 0xDDDD22;
    sa_Achievement.boxColor    0xFFFFFF;
  }
}

class ia_TenKills : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Imp Killer";
    sa_Achievement.description "Kill 10 imps";
    sa_Achievement.limit 10;
    sa_Achievement.borderColor 0xDD2222;
    sa_Achievement.boxColor    0xDDDD22;
  }
}

class ia_100Kills : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Imp Exterminator";
    sa_Achievement.description "Kill 100 imps";
    sa_Achievement.limit 100;
    sa_Achievement.borderColor 0x990000;
    sa_Achievement.boxColor    0xDD2222;
  }
}

class ia_666Kills : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Imp Slayer";
    sa_Achievement.description "Kill 666 imps";
    sa_Achievement.limit 666;
    sa_Achievement.borderColor 0x000000;
    sa_Achievement.boxColor    0x990000;
  }
}

class ia_Telefrag : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Telehopper";
    sa_Achievement.description "Telefrag an imp";
    sa_Achievement.borderColor 0x509e43;
    sa_Achievement.boxColor    0xcaa53b;
    sa_Achievement.isHidden true;
  }
}

class ia_Shadow : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Shadowy";
    sa_Achievement.description "Make an imp cast a shadow";
    sa_Achievement.borderColor 0x555555;
    sa_Achievement.boxColor    0x000000;
  }
}

// This achievement is kind of broken: notification doesn't have enough time
// to show properly before the level ends.
class ia_Friend : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Imp Friend";
    sa_Achievement.description "Don't kill any imp on the level";
    sa_Achievement.borderColor 0x000000;
    sa_Achievement.boxColor    0x00AA00;
  }
}

class ia_Overkill : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Overkill";
    sa_Achievement.description "Kill an imp more than usual";
  }
}

class ia_Melee : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Come closer";
    sa_Achievement.description "Hit imps 100 times with melee attack\n\nCome here... Now we are talking!";
    sa_Achievement.limit 100;
  }
}
