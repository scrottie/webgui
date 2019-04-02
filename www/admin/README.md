# AlliumCepa Admin Interface Unofficial

In the abscense of a good/natural Perl CMS system that is OpenSource I decided to give this another look and possibly revive this CMS.

There are NO guarantees that this project will be supported.  As a matter of fact the project may be used as inspiration to write a similar version in [Perl6](https://perl6.org).

### Tech

The developers use a variety of resources to support this project:

* [Docker &copy;](https://www.docker.com) - Docker resources
* [Docker Compose](https://docs.docker.com/compose/overview/) - Docker compose
* [AlliumCepa](https://github.com/AlliumCepa/webgui) - Content Management System
* [MariaDB &copy;](https://mariadb.org) - MariaDB
* [Netbeans &copy;](https://netbeans.org) - Netbeans (Developer IDE)
* [Netbeans Perl Plugin](http://plugins.netbeans.org/plugin/36183/perl-on-netbeans) - Netbeans Perl Plugin
* [React](https://reactjs.org) - React, JavaScript Framework
* [Redux](https://redux.js.org) - Redux, A predictable state container for JavaScript apps
* [Git](https://git-scm.com) - Git, version control system 

### Installation
Start the Docker Engine in your local environemt

```sh
$ git clone https://github.com/AlliumCepa/webgui.git
$ cd webgui
$ docker build -t webgui:local .
$ cd docs
$ docker-compose up
```

Verify the deployment by navigating to your systems local address in your preferred browser.

```sh
http://localhost
```

### Development

Want to contribute? Great!
Contact https://github.com/AlliumCepa/webgui 


**Free Software, Hell Yeah!**