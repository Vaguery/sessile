# Revisiting the Moore Lab's "CES" system

I recently visited Jason Moore and his team at Dartmouth's [Computational Genetics Lab](http://www.epistasis.org). Jason and his folks have been coming to the [GPTP workshops](http://www.lsa.umich.edu/cscs/events/annualevents/geneticprogrammingtheoryandpracticeworkshop) for a long time now, and one of the projects they often present results from is something they call their ["Computational Evolution System"](http://scholar.google.com/scholar?q=moore+%22Computational+Evolution+System%22).

I've never really understood how it works. I'm sure I understand the motivation and even some of the implicit design patterns it implements, but there's an awful lot of stuff in there doing (or possibly not doing) an awful lot of different things to the dynamics of what could be a straightforward genetic programming system.

So rather than digging around in a mess of somebody else's C++ code, I've talked Jason and his colleagues into helping me write some code of my own, using a leaner approach. This isn't intended to be a "replacement" or even "rebuild" of CES. Nor is it a replication made from some sort of validation/verificationist sensibility. It's a different piece of software already from anything CES ever has been. The value, as far as I'm concerned comes from the process and conversation around the goals and means, not the application of the code as a tool in some particular work environment.

## The core

If I can summarize a lot of work much too simply, the intent of CES is the discovery of novel explanatory models relating genetic traits to particular disease states. These "genetic traits" are specifically [SNPs](http://en.wikipedia.org/wiki/Single-nucleotide_polymorphism), and the diseases in question are things like bladder cancer or autism.

Now the reason we're talking about "novel explanatory models" and not just "finding genes" has a lot to do with the way actual biology works, and I'm not going to try to explain epistasis or epigenetics to you in a place like this. Suffice to say: if you think it's fruitful (or even interesting) to identify *single SNPs* that "cause" diseases all by themselves, then a judge ought to suspend your Biology License until you go get remedial genetics training.

Real life is complicated, even when we're talking about something as abstracted as the relation between DNA sequences and well-defined disease states. What CES looks for are relatively complex *functional relationships* between multiple SNPs and the various disease outcomes of interest. Each SNP is present in a dose of zero, one or two copies in every individual, and many genetic effects are dose-dependent; sequence polymorphism can affect everything from the local folding and melting traits of the DNA molecule, to the binding properties of a multitude of macromolecular participants in gene regulation and expression, to the rates at which genes are expressed (locally *and* remotely), and finally even the thing most ignorant souls imagine---presence or absence of a gene product.

In other words: *genetic disease is not about individual genes*. It almost never is.

At its core, CES implements what (to me) seems a straightforward single-typed stack-based arithmetic-plus-a-bit-of-conditional method to capture more of these possibilities than simple presence-vs.-absence univariate statistics could hope to do. It takes the observed values of an individual patient's SNPs as "inputs", and returns a floating-point value as a (contextually thresholded) prediction of their disease state.

The data being used for training and testing is (again, at its core) a pretty simple table:

- input columns are SNPs,
- output columns are categorical variables describing disease state (or possibly quantitative measures of severity),
- each row is one patient,
- each input cell is that patient's *dose* of the indicated SNP: zero, one or two copies.

A *prospective* model is represented as a stack-based arithmetic function, written as a script of tokens *in any order or number* from the following sets:

- the SNPs, which are arguments (the dose values are converted to floats), 
- arithmetic operators on two inputs (`plus`, `times`, `minus`, `protected_divide`), which return floats,
- comparison operators on two inputs (`less_than?`, `greater_than?`, `equal?` and so forth), which return `0.0` or `1.0` for `false` and `true`,
- some extra input variables, maybe (see next section).

With not too much complexity elided, a CES model is represented as a *script* of arbitrary tokens, and is executed in left-to-right order, one step at a time. For example, `x_3 x_1 + x_2 < x_1 +` is a valid script, in which the result will be the equivalent of `((x_1 + x_3) < x_2 ? 1.0 : 0.0) + x_1` (representing the comparison as a ternary operation).

As with most stack-based languages, the variable tokens (SNPs) push the associated value onto the working stack (which is initially empty), and the operators remove their arguments from that stack and push the result back onto it. If there aren't enough arguments on the stack, an operator fails. Over the course of executing an arbitrary script, an arbitrary number of items might end up being pushed onto the stack and removed.

When a model is *run* on a given training or test case, the *result* is the topmost value on the stack. If no values are present at the end of executing the script, an error is returned.

To *evaluate* a given model over a set of data, it's *run* once for each row, and the numerical results are associated with each row. Through a process we'll explore in more detail later, these results are compared to the observed disease states of the patients, and a single *error statistic* is calculated for the prospective model.

## The extra stuff

As I said, *at its core* CES is about these little arithmetic models. But it includes an awful lot of other stuff as well: there are multiple "layers" of dynamics, stacked on top of one another and making all kinds of nominally adaptive changes to the state of a "run". These numerous facets of CES are intended to manage the *dynamics* of CES's search among the scripts I've described, and as such they are more of a control and adaptation infrastructure. I'm going to give a quick summary of what I've gleaned, but it's not salient yet to this project:

- systems for managing the way new scripts are generated over time
- systems for managing additional data sources (and "domain knowledge") that can inform the choice of SNPs and the types of relations between them
- systems for managing the way CES as a whole "learns" over time
- and so on.

All this "extra" stuff is, in a real sense, the *reason* for CES as it exists today. But it's all very interconnected and [counter-]intuitive, and above all it's contingent on work people did a long time ago. People who aren't me. So it's a big ball of legacy code, as far as I'm concerned.

My goal here is to uncover and explore the *reasons* some of that extra stuff is present. If not for the many extant blobs and versions of CES, then at least for the code I write as I build up a  lean, simplified, goal-driven approximation. Thus...

## Minimum Viable Project

I'm ignoring all of the "extra stuff" for now.

One thing that struck me as I visited Dartmouth a few weeks back is how Jason said in passing that it's "impossible" to find good models with just plain approaches. I'm quite sure that the design complexity I see in CES's "extra stuff" was an attempt to address that, but (a) I don't know personally what "impossible" means to Jason, (b) I doubt that all that stuff was created incrementally to address well-specified *improvements* on the path from "impossible" to "working", and (c) simultaneously applying five good and complicated ideas does not often result in one simple and understandable solution.

My point is to surface what happens as we simultaneously tease apart the big ball of mud---which I'll need to do in order to understand what the "extra stuff" actually *does*---and also start a fresh path into the intentional place where CES appears to *deliver value*.

So the first thing to do, seems to me, is to build an equivalent core: an interpreter that will run and evaluate models of the sort I've described above.