class ia_EventHandler : EventHandler
{

  override
  void NetworkProcess(ConsoleEvent event)
  {
    if (event.Name == "ia_test")
    {
      sa_Achiever.achieve("sa_Achievement");
    }
  }

} // class ia_EventHandler
