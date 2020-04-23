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
  void worldThingDied(WorldEvent event)
  {
    if (isImp(event.thing))
    {
      sa_Achiever.achieve("ia_OneKill");
      sa_Achiever.achieve("ia_TenKills");
      sa_Achiever.achieve("ia_100Kills");
      sa_Achiever.achieve("ia_666Kills");
    }
  }

  private
  bool isImp(Actor a)
  {
    bool isReplacingImp = ("DoomImp" == Actor.getReplacee(a.getClass()));
    bool isBasedOnImp   = (a is "DoomImp");
    return (isReplacingImp || isBasedOnImp);
  }

} // class ia_EventHandler

class ia_OneKill : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Initiate";
    sa_Achievement.description "Kill one imp";
    sa_Achievement.borderColor 0xDD2222;
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
    sa_Achievement.borderColor 0xDD2222;
    sa_Achievement.boxColor    0xDD6622;
  }
}

class ia_666Kills : sa_Achievement
{
  Default
  {
    sa_Achievement.name "Imp Slayer";
    sa_Achievement.description "Kill 666 imps";
    sa_Achievement.limit 666;
    sa_Achievement.borderColor 0xDD2222;
    sa_Achievement.boxColor    0x000000;
  }
}
