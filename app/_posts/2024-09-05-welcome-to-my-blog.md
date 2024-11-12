---
layout: post
title:  "Welcome to my blog!"
date:   2024-09-05 20:00:00 +0000
categories: blog news update
---
# Introduction
My name is Lucas. I'm a data engineer at Zurich Insurance, and I'm currently planning to learn about Kubernetes. This blog
will be my journal of that learning experience, where I will share what I'm learning, playing with, trying out, and some
random ideas.

# My developer profile

I have worked mainly as an ETL developer using Spark, both with Scala and Python, and also done some backend
development. I have professional experience both in AWS and Azure (I've only played with GCP for personal never-finished
projects), and have a semi-strong foundation of the concepts of containers, having used mainly Docker and more recently
Docker compose.

# How am I planning to learn Kubernetes?
A great coworker who is (at least from my current perspective) a complete Kubernetes god will be mentoring me. He is a
SRE (Site reliability Engineer) and has extensive experience with K8s. Me and two more developers will be his mentees,
and we will meet at least once a month to talk K8s, see our progress, solve doubts, etc.

Besides this I don't currently have much more details on how things will go. I will probably post an update with a learning
plan, which hopefully will have a high level overview of the topics we will touch. For now, just know that the goal is
to have a complete view of Kubernetes, from deployment and monitoring to networking and security. We will see technologies
like ArgoCD, Nginx, and probably a lot more that I don't even know the name of yet.

Parallel to this learning, my idea is to set up a home cluster with a couple of RaspberryPIs (hopefully they have enough
compute capacity to host a MicroK8s, I honestly don't know right now), and migrate some services that I'm currently
running on them using Docker Compose, things like my personal website, a media server, a spotify streamer for my analog
amplifier, etc.

# The blog
I will try to keep the blog up to date so that I can have a written log of what I do during this learning, and hopefully
someone will read this at some point (hey you!) and find it interesting, helpful, or will at least be able to do a quick
CTRL+C, CTRL+V of something written here.

The blog itself will be hosted on a Raspberry Pi Zero W, and while initialy the idea was to have it within the K8s cluster
mentioned earlier, I have realised that it is probably better to have it outside of it so that the blog still works when
I inevitably mess things up. The source "code" for it can be found in the blog's
[GitHub Repo](https://github.com/lucascajal/blog).

That's it for now, thanks for reading!
