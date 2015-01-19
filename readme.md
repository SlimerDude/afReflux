#Reflux v0.0.0
---
[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](http://fantom.org/)
[![pod: v0.0.0](http://img.shields.io/badge/pod-v0.0.0-yellow.svg)](http://www.fantomfactory.org/pods/afReflux)
![Licence: MIT](http://img.shields.io/badge/licence-MIT-blue.svg)

## Overview

A framework for creating a simple FWT desktop applications.

Fantom's core `flux` framework has the notion of being a URI browser. Reflux takes this idea and adds into the mix:

- **An IoC container** - Relflux applications are IoC applications.
- **Events** - An application wide eventing mechanism.
- **Customisation** - All aspects of a Reflux application may be customised.
- **Context sensitive commands** - Global commands may be enabled / disabled.
- **Browser session** - A consistent means to store session data.
- **New FWT widgits** - Fancy tabs and a working web browser.

The goal of Reflux is to be a customisable application framework; this differs to `flux` which is more of a static application with custom plugins.

> Reflux = Flux -> Reloaded.

## Install

Install `Reflux` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afReflux

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afReflux 0.0"]

## Documentation

Full API & fandocs are available on the [Status302 repository](http://repo.status302.com/doc/afReflux/).

![afReflux.ctabs.png](afReflux.ctabs.png)

## Quick Start

## Usage

### Panels

[Panels](http://repo.status302.com/doc/afReflux/Panel.html) are widget panes that decorate the edges of the main window. Only one instance of each panel type may exist. They are typically created at application startup and live until the application shuts down.

To create a custom panel, first create a class that extends [Panel](http://repo.status302.com/doc/afReflux/Panel.html). This example just sets its FWT content to a yellow label:

```
class MyPanel : Panel {
    new make(|This| in) : super(in) { 
        content = Label() {
            it.text = "Hello Mum!"
            it.bg   = Color.yellow
        }
    }
}
```

Note that the Panel's ctor must take an `it-block` parameter and pass it up to the superclass to be executed. This is so IoC can inject all those lovely dependencies. Now contribute an instance of the panel to the `Panels` service in your `AppModule`:

```
class AppModule {
    @Contribute { serviceType=Panels# }
    static Void contributePanels(Configuration config) {
    	myPanel := config.autobuild(MyPanel#)
        config.add(myPanel)
    }
}
```

Panels need to be *autobuilt* so IoC injects all the depdencies (via that it-block ctor parameter).

Panels are automatically added to the `View -> Panels` menu; select it to display it:

![Screenshot of Panel Example](afReflux.panelExample.png)

Note that Panels are not displayed by default; but the user's display settings are saved from one session to the next. To force the user to always start with your panel displayed, show it progamatically on application startup:

```
Reflux.start("Example", [AppModule#]) |Reflux reflux, Window window| {
    reflux.showPanel(MyPanel#)
} 
```

Panels contain several callback methods that are invoked at different times of its lifecycle. These are:

- `onShow()` - called when it's added to the tab pane.
- `onActivate()` - called when it becomes the active tab.
- `onModify()` - called when panel details are modified, such as the name or icon.
- `onDeactivate()` - called when some other tab becomes active.
- `onHide()` - called when it is removed from the tab pane.
- `refresh()` - called when the panel `isShowing` and the refresh button is clicked.

Panels are automatically added to the `EventHub` - see [Eventing](http://repo.status302.com/doc/afReflux/#eventing.html) for details.

