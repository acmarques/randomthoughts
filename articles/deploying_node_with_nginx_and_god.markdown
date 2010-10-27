Title: Deploying Node.js apps with Nginx and God
Author: Antonio Marques
Date: Tue Oct 26 2010 12:38:25 GMT-0700 (PDT)
Node: v0.2.3

The first article lala using graphs to describe JavaScript semantics was so popular that I've decided to try the technique with some more advanced ideas.  In this article I'll explain three common techniques for creating objects.  They are constructor with prototype, pure prototypal, and object factory.

My goal is that this will help people understand the strengths and weaknesses of each technique and understand what's really going on.

## Classical JavaScript Constructors

First let's create a simple constructor function with a prototype.  This is the closest thing to a class you're going to find in native JavaScript.  It's extremely powerful and efficient, but doesn't quite work like you would expect if coming from a language with classes.


## Conclusion

There is so much more I want to explore, but I like to keep these articles somewhat short and bite-size.  If there is demand, I'll write a part three explaining how to do ruby-style mixins and other advanced topics.