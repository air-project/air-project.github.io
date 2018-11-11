---
title: 深度解析Java 8：AbstractQueuedSynchronizer的实现分析（下）
date: 2018-09-24 18:32:39
commentIssueId: 11
tags:
---

## 前言

经过本系列的上半部分JDK1.8 AbstractQueuedSynchronizer的实现分析（上）的解读，相信很多读者已经对AbstractQueuedSynchronizer(下文简称AQS)的独占功能了然于胸,
那么这次我们通过对另一个工具类:CountDownLatch的分析来解读AQS的另外一个功能：共享功能。

### AQS共享功能的实现

在开始解读AQS的共享功能前，我们再重温一下CountDownLatch，CountDownLatch为java.util.concurrent包下的计数器工具类，
常被用在多线程环境下，它在初始时需要指定一个计数器的大小，然后可被多个线程并发的实现减1操作，并在计数器为0后调用await方法的线程被唤醒，
从而实现多线程间的协作。它在多线程环境下的基本使用方式为：
 ```
  //main thread
  // 新建一个CountDownLatch，并指制定一个初始大小
  CountDownLatch countDownLatch = new CountDownLatch(3);
  // 调用await方法后，main线程将阻塞在这里，直到countDownLatch 中的计数为0 
  countDownLatch.await();
  System.out.println("over");

 //thread1
 // do something 
 //...........
 //调用countDown方法，将计数减1
  countDownLatch.countDown();


 //thread2
 // do something 
 //...........
 //调用countDown方法，将计数减1
  countDownLatch.countDown();

   //thread3
 // do something 
 //...........
 //调用countDown方法，将计数减1
  countDownLatch.countDown();
```
 
 注意，线程thread 1,2,3各自调用 countDown后，countDownLatch 的计数为0，await方法返回，控制台输入“over”,在此之前main thread 会一直沉睡。

可以看到CountDownLatch的作用类似于一个“栏栅”，在CountDownLatch的计数为0前，调用await方法的线程将一直阻塞，直到CountDownLatch计数为0，await方法才会返回，

而CountDownLatch的countDown()方法则一般由各个线程调用，实现CountDownLatch计数的减1。

知道了CountDownLatch的基本使用方式，我们就从上述DEMO的第一行new CountDownLatch（3）开始，看看CountDownLatch是怎么实现的。

<!-- more -->

首先，看下CountDownLatch的构造方法：
```
public CountDownLatch(int count) {
    if (count < 0) throw new IllegalArgumentException("count < 0");
    this.sync = new Sync(count);
}
```
和ReentrantLock类似，CountDownLatch内部也有一个叫做Sync的内部类，同样也是用它继承了AQS。

再看下Sync：
```
Sync(int count) {
    setState(count);
}
```
如果你看过本系列的上半部分，你对setState方法一定不会陌生，它是AQS的一个“状态位”，在不同的场景下，代表不同的含义，比如在ReentrantLock中，表示加锁的次数，在CountDownLatch中，则表示CountDownLatch的计数器的初始大小。
![](https://res.infoq.com/articles/java8-abstractqueuedsynchronizer/zh/resources/0815012.png)  
设置完计数器大小后CountDownLatch的构造方法返回，下面我们再看下CountDownLatch的await()方法：
```
public void await() throws InterruptedException {
    sync.acquireSharedInterruptibly(1);
}
```
调用了Sync的acquireSharedInterruptibly方法，因为Sync是AQS子类的原因，这里其实是直接调用了AQS的acquireSharedInterruptibly方法：
```
public final void acquireSharedInterruptibly(int arg)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    if (tryAcquireShared(arg) < 0)
        doAcquireSharedInterruptibly(arg);
}
```
从方法名上看，这个方法的调用是响应线程的打断的，所以在前两行会检查下线程是否被打断。接着，尝试着获取共享锁，小于0，表示获取失败，通过本系列的上半部分的解读， 我们知道AQS在获取锁的思路是，先尝试直接获取锁，如果失败会将当前线程放在队列中，按照FIFO的原则等待锁。而对于共享锁也是这个思路，如果和独占锁一致，这里的tryAcquireShared应该是个空方法，留给子类去判断:
```
protected int tryAcquireShared(int arg) {
    throw new UnsupportedOperationException();
}
```
再看看CountDownLatch：
```
protected int tryAcquireShared(int acquires) {
    return (getState() == 0) ? 1 : -1;
}
```
如果state变成0了，则返回1，表示获取成功，否则返回-1则表示获取失败。

看到这里，读者可能会发现， await方法的获取方式更像是在获取一个独占锁，那为什么这里还会用tryAcquireShared呢？

回想下CountDownLatch的await方法是不是只能在主线程中调用？答案是否定的，CountDownLatch的await方法可以在多个线程中调用，当CountDownLatch的计数器为0后，调用await的方法都会依次返回。 也就是说可以多个线程同时在等待await方法返回，所以它被设计成了实现tryAcquireShared方法，获取的是一个共享锁，锁在所有调用await方法的线程间共享，所以叫共享锁。

回到acquireSharedInterruptibly方法：
```
public final void acquireSharedInterruptibly(int arg)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    if (tryAcquireShared(arg) < 0)
        doAcquireSharedInterruptibly(arg);
}
```
如果获取共享锁失败（返回了-1，说明state不为0，也就是CountDownLatch的计数器还不为0），进入调用doAcquireSharedInterruptibly方法中，按照我们上述的猜想，应该是要将当前线程放入到队列中去。

在这之前，我们再回顾一下AQS队列的数据结构：AQS是一个双向链表，通过节点中的next，pre变量分别指向当前节点后一个节点和前一个节点。其中，每个节点中都包含了一个线程和一个类型变量：表示当前节点是独占节点还是共享节点，头节点中的线程为正在占有锁的线程，而后的所有节点的线程表示为正在等待获取锁的线程。如下图所示：  
![](https://res.infoq.com/articles/java8-abstractqueuedsynchronizer/zh/resources/0815018.png)  
黄色节点为头节点，表示正在获取锁的节点，剩下的蓝色节点（Node1、Node2、Node3）为正在等待锁的节点，他们通过各自的next、pre变量分别指向前后节点，形成了AQS中的双向链表。每个线程被加上类型（共享还是独占）后便是一个Node， 也就是本文中说的节点。

再看看doAcquireSharedInterruptibly方法：
```
private void doAcquireSharedInterruptibly(int arg)
        throws InterruptedException {
        final Node node = addWaiter(Node.SHARED); 
//将当前线程包装为类型为Node.SHARED的节点，标示这是一个共享节点。
        boolean failed = true;
        try {
            for (;;) {
                final Node p = node.predecessor();
                if (p == head) {
//如果新建节点的前一个节点，就是Head，说明当前节点是AQS队列中等待获取锁的第一个节点，
//按照FIFO的原则，可以直接尝试获取锁。
                    int r = tryAcquireShared(arg);
                    if (r >= 0) {
                        setHeadAndPropagate(node, r); 
//获取成功，需要将当前节点设置为AQS队列中的第一个节点，这是AQS的规则//队列的头节点表示正在获取锁的节点
                        p.next = null; // help GC
                        failed = false;
                        return;
                    }
                }
                if (shouldParkAfterFailedAcquire(p, node) && //检查下是否需要将当前节点挂起
                    parkAndCheckInterrupt()) 
                    throw new InterruptedException();
            }
        } finally {
            if (failed)
                cancelAcquire(node);
        }
    }
```
这里有几点需要说明的：

1. setHeadAndPropagate方法：
```
private void setHeadAndPropagate(Node node, int propagate) {
    Node h = head; // Record old head for check below
    setHead(node); 
    if (propagate > 0 || h == null || h.waitStatus < 0 ||
        (h = head) == null || h.waitStatus < 0) {
        Node s = node.next;
        if (s == null || s.isShared())
            doReleaseShared();
    }
}
```
    
首先，使用了CAS更换了头节点，然后，将当前节点的下一个节点取出来，如果同样是“shared”类型的，再做一个"releaseShared"操作。

看下doReleaseShared方法：
```
for (;;) {
            Node h = head;
            if (h != null && h != tail) {
                int ws = h.waitStatus;
                if (ws == Node.SIGNAL) { 
                    if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0)) 
//如果当前节点是SIGNAL意味着，它正在等待一个信号，  
//或者说，它在等待被唤醒，因此做两件事，1是重置waitStatus标志位，2是重置成功后,唤醒下一个节点。
                        continue;            // loop to recheck cases
                    unparkSuccessor(h);
                }
                else if (ws == 0 &&
                         !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))  
//如果本身头节点的waitStatus是出于重置状态（waitStatus==0）的，将其设置为“传播”状态。
//意味着需要将状态向后一个节点传播。
                    continue;                // loop on failed CAS
            }
            if (h == head)                   // loop if head changed
                break;
        }
```
为什么要这么做呢？这就是共享功能和独占功能最不一样的地方，对于独占功能来说，有且只有一个线程（通常只对应一个节点，拿ReentantLock举例，如果当前持有锁的线程重复调用lock()方法，那根据本系列上半部分我们的介绍，我们知道，会被包装成多个节点在AQS的队列中，所以用一个线程来描述更准确），能够获取锁，但是对于共享功能来说。

共享的状态是可以被共享的，也就是意味着其他AQS队列中的其他节点也应能第一时间知道状态的变化。因此，一个节点获取到共享状态流程图是这样的：
比如现在有如下队列：
当Node1调用tryAcquireShared成功后，更换了头节点： 
![](https://res.infoq.com/articles/java8-abstractqueuedsynchronizer/zh/resources/0815020.png)  
     Node1变成了头节点然后调用unparkSuccessor()方法唤醒了Node2、Node2中持有的线程A出于上面流程图的park node的位置，

线程A被唤醒后，重复黄色线条的流程，重新检查调用tryAcquireShared方法，看能否成功，如果成功，则又更改头节点，重复以上步骤，以实现节点自身获取共享锁成功后，唤醒下一个共享类型节点的操作，实现共享状态的向后传递。

2.其实对于doAcquireShared方法，AQS还提供了集中类似的实现：  
![](https://res.infoq.com/articles/java8-abstractqueuedsynchronizer/zh/resources/0815021.png)   
分别对应了：
1. 带参数请求共享锁。 （忽略中断）
2. 带参数请求共享锁，且响应中断。（每次循环时，会检查当前线程的中断状态，以实现对线程中断的响应）
3. 带参数请求共享锁但是限制等待时间。（第二个参数设置超时时间，超出时间后，方法返回。）
![](https://res.infoq.com/articles/java8-abstractqueuedsynchronizer/zh/resources/0815022.png)  
比较特别的为最后一个doAcquireSharedNanos方法，我们一起看下它怎么实现超时时间的控制的。

因为该方法和其余获取共享锁的方法逻辑是类似的，我用红色框圈出了它所不一样的地方，也就是实现超时时间控制的地方。

可以看到，其实就是在进入方法时，计算出了一个“deadline”，每次循环的时候用当前时间和“deadline”比较，大于“dealine”说明超时时间已到，直接返回方法。

注意，最后一个红框中的这行代码：
```
nanosTimeout > spinForTimeoutThreshold
```
从变量的字面意思可知，这是拿超时时间和超时自旋的最小作比较，在这里Doug Lea把超时自旋的阈值设置成了1000ns,即只有超时时间大于1000ns才会去挂起线程，否则，再次循环，以实现“自旋”操作。这是“自旋”在AQS中的应用之处。

看完await方法，我们再来看下countDown()方法：
```
public void countDown() {
    sync.releaseShared(1);
}
```
调用了AQS的releaseShared方法,并传入了参数1:
```
public final boolean releaseShared(int arg) {
    if (tryReleaseShared(arg)) {
        doReleaseShared();
        return true;
    }
    return false;
}
```
同样先尝试去释放锁，tryReleaseShared同样为空方法，留给子类自己去实现，以下是CountDownLatch的内部类Sync的实现：
```
protected boolean tryReleaseShared(int releases) {
        // Decrement count; signal when transition to zero
        for (;;) {
            int c = getState();
            if (c == 0)
                return false;
            int nextc = c-1;
            if (compareAndSetState(c, nextc))
                return nextc == 0;
        }
    }
```

死循环更新state的值，实现state的减1操作，之所以用死循环是为了确保state值的更新成功。

从上文的分析中可知，如果state的值为0，在CountDownLatch中意味：所有的子线程已经执行完毕，这个时候可以唤醒调用await()方法的线程了，而这些线程正在AQS的队列中，并被挂起的，

所以下一步应该去唤醒AQS队列中的头节点了（AQS的队列为FIFO队列），然后由头节点去依次唤醒AQS队列中的其他共享节点。

如果tryReleaseShared返回true,进入doReleaseShared()方法：
```
private void doReleaseShared() {
        for (;;) {
            Node h = head;
            if (h != null && h != tail) {
                int ws = h.waitStatus;
                if (ws == Node.SIGNAL) { 
                    if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0)) 
//如果当前节点是SIGNAL意味着，它正在等待一个信号，
 //或者说，它在等待被唤醒，因此做两件事，1是重置waitStatus标志位，2是重置成功后,唤醒下一个节点。
                        continue;            // loop to recheck cases
                    unparkSuccessor(h);
                }
                else if (ws == 0 &&
                         !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))  
//如果本身头节点的waitStatus是出于重置状态（waitStatus==0）的，将其设置为“传播”状态。
//意味着需要将状态向后一个节点传播。
                    continue;                // loop on failed CAS
            }
            if (h == head)                   // loop if head changed
                break;
        }
  }
  ```
当线程被唤醒后，会重新尝试获取共享锁，而对于CountDownLatch线程获取共享锁判断依据是state是否为0，而这个时候显然state已经变成了0，因此可以顺利获取共享锁并且依次唤醒AQS队里中后面的节点及对应的线程。

### 总结

本文从CountDownLatch入手，深入分析了AQS关于共享锁方面的实现方式：

如果获取共享锁失败后，将请求共享锁的线程封装成Node对象放入AQS的队列中，并挂起Node对象对应的线程，实现请求锁线程的等待操作。待共享锁可以被获取后，从头节点开始，依次唤醒头节点及其以后的所有共享类型的节点。实现共享状态的传播。

这里有几点值得注意：
与AQS的独占功能一样，共享锁是否可以被获取的判断为空方法，交由子类去实现。
与AQS的独占功能不同，当锁被头节点获取后，独占功能是只有头节点获取锁，其余节点的线程继续沉睡，等待锁被释放后，才会唤醒下一个节点的线程，而共享功能是只要头节点获取锁成功，就在唤醒自身节点对应的线程的同时，继续唤醒AQS队列中的下一个节点的线程，每个节点在唤醒自身的同时还会唤醒下一个节点对应的线程，以实现共享状态的“向后传播”，从而实现共享功能。
以上的分析都是从AQS子类的角度去看待AQS的部分功能的，而如果直接看待AQS，或许可以这么去解读：

首先，AQS并不关心“是什么锁”，对于AQS来说它只是实现了一系列的用于判断“资源”是否可以访问的API,并且封装了在“访问资源”受限时将请求访问的线程的加入队列、挂起、唤醒等操作， AQS只关心“资源不可以访问时，怎么处理？”、“资源是可以被同时访问，还是在同一时间只能被一个线程访问？”、“如果有线程等不及资源了，怎么从AQS的队列中退出？”等一系列围绕资源访问的问题，而至于“资源是否可以被访问？”这个问题则交给AQS的子类去实现。

当AQS的子类是实现独占功能时，例如ReentrantLock，“资源是否可以被访问”被定义为只要AQS的state变量不为0，并且持有锁的线程不是当前线程，则代表资源不能访问。

当AQS的子类是实现共享功能时，例如：CountDownLatch，“资源是否可以被访问”被定义为只要AQS的state变量不为0，说明资源不能访问。

这是典型的将规则和操作分开的设计思路：规则子类定义，操作逻辑因为具有公用性，放在父类中去封装。

当然，正式因为AQS只是关心“资源在什么条件下可被访问”，所以子类还可以同时使用AQS的共享功能和独占功能的API以实现更为复杂的功能。

比如：ReentrantReadWriteLock，我们知道ReentrantReadWriteLock的中也有一个叫Sync的内部类继承了AQS，而AQS的队列可以同时存放共享锁和独占锁，对于ReentrantReadWriteLock来说分别代表读锁和写锁，当队列中的头节点为读锁时，代表读操作可以执行，而写操作不能执行，因此请求写操作的线程会被挂起，当读操作依次推出后，写锁成为头节点，请求写操作的线程被唤醒，可以执行写操作，而此时的读请求将被封装成Node放入AQS的队列中。如此往复，实现读写锁的读写交替进行。

而本系列文章上半部分提到的FutureTask，其实思路也是：封装一个存放线程执行结果的变量A,使用AQS的独占API实现线程对变量A的独占访问，判断规则是，线程没有执行完毕：call()方法没有返回前，不能访问变量A，或者是超时时间没到前不能访问变量A(这就是FutureTask的get方法可以实现获取线程执行结果时，设置超时时间的原因)。   
原网页地址：http://www.infoq.com/cn/articles/java8-abstractqueuedsynchronizer#

最后欢迎到这里提PR，我会即使回复