# Overview of Entity Component System (ECS) variations with pseudo-code

For background and further references see: [Entity Component Systems on Wikipedia](https://en.wikipedia.org/wiki/Entity_component_system)

### ECS by Scott Bilas ([GDC 2002](http://scottbilas.com/files/2002/gdc_san_jose/game_objects_slides_with_notes.pdf))

##### Entity->Components->Update

- `entity` = class: no logic + no data OR at most small set of frequently used data (ie position)
- `component` = class: logic + data
```
foreach entity in allEntities do
    foreach component in entity.components do
	    component.update()
	end
end
```

### ECS by Scott Bilas
##### ComponentTypes->Components->Update

- `entity` & `component` = same as in Bilas' ECS
- `componentSystem` = array of components of the same class
- Note: goal is to enforce component-type update order, ie ensure physics components update before render components regardless of their order within the entity components lists.
- Added benefit: entities can be hierarchical while components remain a "flat" array.

```
foreach componentSystem in allComponentSystems do
	foreach component in componentSystem.components do
		component.update()
	end
end
```


### ECS by Apple's GameplayKit
##### ComponentTypes->Components->Update

- `entity` & `component` = same as in Bilas' ECS
- `componentSystem` = same as in Bilas' ECS variant
- Note: GameplayKit also supports *Entity->Components->Update*
	- Both update approaches could even be mixed but care must be taken to prevent components from updating twice per frame/step.
```
foreach componentSystem in allComponentSystems do
	componentSystem.update() // inner loop encapsulated by GKComponentSystem
end
```


### [ECS by Adam Martin](http://entity-systems.wikidot.com)
##### ComponentTypes->Components->Update

- `entity` = index (aka `ID`), not a class, no logic, no data
- `component` = class or struct: no logic, only data
- `componentSystem` = logic + array of components (data) of the same type
```
foreach componentSystem in allComponentSystems do
	foreach component in componentSystem.components do
		// component (data) processing logic inlined here ...
	end
end
```


#### Why the minute difference in Martins' ECS?
Performance optimizations mainly:

- contiguous memory usage, CPU "streaming" or look-ahead optimizations, fewer cache misses
- easier to parallelize both component systems and per-entity updates
- hardware architecture optimizations, ie data is compressed in memory, is decompressed to specific core's local memory for processing, then recompressed and written back to "slow" memory. Particularly effective on PS3's [Cell processor](https://en.wikipedia.org/wiki/Cell_(microprocessor)#Synergistic_Processing_Elements_.28SPE.29).
- easier/faster to (de)serialize data, ideally you can write the entire data directly into a contiguous block of memory
- database/tool export may be easier (ie header of structs or class stubs is easier to generate than modifying class headers with additional logic in them)
- no function call overhead in component system's update loop

#### Which ECS variant is most popular?
Depends.

If you consider AAA console game developers, then Martin's ECS is a de facto standard by now (2015) and I'm guessing became that standard somewhere between 2005-2010 based on developer awareness at the time. Martin's ECS is necessary in order to achieve best performance on console hardware (and as a side-effect improving PC performance as well). I think that's why professional game developers insist that Martin's ECS *is* ECS, not Bilas'. 

To understand this, you have to know that those programmers can be [greatly concerned about the use of virtual functions in C++](http://stackoverflow.com/questions/449827/virtual-functions-and-performance-c). And yes, it can matter, and again: on consoles specifically. But perhaps also mobile devices. But do others care enough, besides AAA developers and system experts?

If you look at the hobbyist, indie and small business sector, things seem to change. Probably because it feels more natural to implement Bilas' approach. It may even be the only or best solution they can (easily) implement in the given game engine they are using. 

Typically the initial solution to a problem is most used anyway, because it solves the given problem well and then there's rarely need to find a more specialized solution that solves the same problem again, "just better".

In this case, Martin's ECS is different, arguably better, but really offers no strikingly obvious benefit in terms of code architecture, error rate, readability, maintainability and such. The things that matter most to small businesses and non-experts is anything but utmost performance/efficiency (exceptions notwithstanding). Fast enough is good enough.

So Bilas' approach is still prevalent in the space beside the AA(A) industry, and my assumption is that quantitatively Bilas' ECS is still the most popular implementation by far.


#### Is it possible to implement Martin's ECS with GameplayKit?
Yes. This should even work with built-in GKComponent classes like GKAgent. 

Implementation suggestion:

- use GKComponent subclasses as components
- subclass GKComponentSystem -> generic GKComponentProcessor or specialized processors, eg: GKInventoryProcessor, GKSpellcastingProcessor, etc.
- add your component instances to the GKComponentProcessor as usual
- override updateWithDeltaTime: and implement it so that it enumerates the components array and performs the necessary component logic, using each component's data (properties or public ivars). 
    - Do not call [super updateWithDeltaTime:] as this would send the update message to each component.
    - For any built-in component class (eg GKAgent2D) you *have* to send each component the updateWithDeltaTime: message. Or just use a regular GKComponentSystem for the built-in components.
- call updateWithDeltaTime: on GKComponentProcessor instances

Optional steps:
- subclass GKEntity and add `@property uint32_t uniqueID;` so you can identify entities
- create a GKEntitySystem class that stores entities and can return an entity by its `uniqueID`

Hint: If you don't want to subclass GKComponent for your components it will be more difficult to implement. You will probably have to implement Martin's ECS from scratch, not using any of GameplayKit's ECS classes. But it's certainly doable and should interface well with GameplayKit and the rendering engine. Is it worth the time investiment? That's up to you.

### *Personal Note*

I've only ever worked with Bilas' ECS variants, never Martin's. However I was aware of the concept but always felt it applies best to AAA games where it became a necessity due to the console hardware architecture and the rise of multi-core CPUs since (roughly) 2005. 

I was in a team that was using and at the time adapting an engine using Bilas' ECS to PS3/X360 hardware. We were well aware that we needed to re-architect our ECS into Martin's ECS variant if we wanted decent game logic performance. However the console port was abandoned before we got this far, and our attempts to optimize the engine for multi-cores fell back to the (at the time) typical thread usage: physics, pathfinding, rendering, audio and the rest. 

Turns out our game logic (scripted RTS scenarios with RPG aspects) was using at most 10-20% CPU time in the most complex scenarios. It averaged around 5% CPU time for most other scenarios, excluding AI and pathfinding which were only making random-access to entities and their data. In our case it was far more effective to have the designers fix overdone and/or inefficient scripts. Again, on console it would have been very different, and early tests confirmed that game logic processing was highly inefficient on consoles as far as I remember.

But set aside memory access and parallelism issues, and it becomes clear that moving the logic from the component to the component system's loop as in Martin's ECS is just a 'minor structural variation' in itself, and needless if you don't (or can't or needn't) make use of the potential performance benefits that data-only components bring with it.

From the perspective of "which is easier to use" or "leads to better code architecture" or "fewer bugs" they're probably all the same within a margin of error. For instance, in Bilas' ECS if you debug the component's update you always have to check where in the loop you are right now (and GameplayKit doesn't even give you this info) while in Martin's ECS you have the loop counter right next to you. On the other hand, it's tempting to add state to the component system's loop in Martin's ECS that might introduce accidental dependencies or might not be serialized. 

Also, most engines (ie Unity) don't even give user a choice in the matter. The more important part is to use an ECS, not which particular implementation to choose.

Overall, from an average indie game developer's perspective, the tradeoffs are minute and the choice is primarily subjective unless you need to seriously optimize your component's update loop. In that case, use Martin's ECS. Otherwise you can safely default to Bilas' ECS, or your subjective preference.

Professional AAA game software engineers may hate me for saying that, and I accept it. :)

### Credits

This gist brought to you by [Steffen Itterheim](https://twitter.com/gaminghorror) who is working on a *GameplayKitExtensions.framework* which may even add an implementation of Martin's ECS for those who insist on having this variant available to them.

Inspired by a Twitter discussion with [Adam Martin](https://twitter.com/t_machine_org), [Richard Lord](https://twitter.com/richard_lord) and [Tallyn Turnbow](https://twitter.com/tallynturnbow) about Apple's GameplayKit release and how that's "not an ECS" but a "disappointing mess". ;)

- http://tilemapkit.com (ObjC/Swift Tilemap Framework with SpriteKit & GameplayKit content)
- http://learn-cocos2d.com (Cocos2D, SpriteBuilder, Objective-C centric)
