# the flake

you need postgres globally, not managed by nix due to permission hell: `brew install postgresql@14`, then `brew services start postgresql@14`. or whatever you use for pkg management if you're like me and are a linux person. figure it out.  

then, init the db:
`initdb --locale=C -E UTF-8 $(brew --prefix)/var/postgresql@14`

then, 
`createdb teleband`

then grab the flake from this repo and put it in your Music-CPR-Backend/ clone's root.  
track it. **this is necessary.**  

then run `nix flake update && nix develop`

you'll be met with commands to proceed.  
