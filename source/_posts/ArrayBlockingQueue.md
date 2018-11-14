---
title: ArrayBlockingQueue
date: 2018-11-13 17:01:32
commentIssueId: 15
tags: 
  - jkd8
categories:
- 源码
---

 

#### 翻译
 
##### 类注释 
 
 ``` 
 /**
 * A bounded {@linkplain BlockingQueue blocking queue} backed by an
 * array.  This queue orders elements FIFO (first-in-first-out).  The
 * <em>head</em> of the queue is that element that has been on the
 * queue the longest time.  The <em>tail</em> of the queue is that
 * element that has been on the queue the shortest time. New elements
 * are inserted at the tail of the queue, and the queue retrieval
 * operations obtain elements at the head of the queue.
 *
 
 一个有限的blocking queue由数组支持。 
 这个队列排列元素FIFO（先进先出）。 
 队列的头部是队列中最长时间的元素。 头部和尾部为什么是最长和最短告知一下我
 队列的尾部是队列中最短时间的元素。 
 新元素插入队列的尾部，队列检索操作获取队列头部的元素
 
 
 * This is a classic &quot;bounded buffer&quot;, in which a
 * fixed-sized array holds elements inserted by producers and
 * extracted by consumers.  Once created, the capacity cannot be
 * changed.  Attempts to {@code put} an element into a full queue
 * will result in the operation blocking; attempts to {@code take} an
 * element from an empty queue will similarly block.
 *
 
   这是一个经典的“有界缓冲区”，其中固定大小的数组保存由生产者插入的元素并由消费者提取。 
   创建后，容量无法更改。 尝试put成满的队列的元件将导致操作阻挡;
   尝试take从空队列的元件将同样地阻塞
    
   
 * This class supports an optional fairness policy for ordering
 * waiting producer and consumer threads.  By default, this ordering
 * is not guaranteed. However, a queue constructed with fairness set
 * to {@code true} grants threads access in FIFO order. Fairness
 * generally decreases throughput but reduces variability and avoids
 * starvation.
 * 
 此类支持可选的公平策略，用于订购等待的生产者和消费者线程。 
 默认情况下，此订单不能保证。 然而，以公平设置为true的队列以FIFO顺序授予线程访问权限。 公平性通常会降低吞吐量，但会降低变异性并避免饥饿
  
 */
 ```

 
<!-- more -->
 

#### 源码

##### 类结构

![](http://pi42kejq1.bkt.clouddn.com/201811132111_514.png?markdown/)


说明：  

1. ArrayBlockingQueue继承于AbstractQueue，并且它实现了BlockingQueue接口。


2. ArrayBlockingQueue内部是通过Object[]数组保存数据的，也就是说ArrayBlockingQueue是一个基于数组的阻塞并发队列，并且在初始化的时候必须指定整个容器的大小（也就是成员变量数组的大小），并且后面也会知道，整个容器是不会扩容的。


3. ArrayBlockingQueue与ReentrantLock是组合关系，ArrayBlockingQueue中包含一个ReentrantLock对象(lock)。ReentrantLock是可重入的互斥锁，ArrayBlockingQueue就是根据该互斥锁实现“多线程对竞争资源的互斥访问”。而且，ReentrantLock分为公平锁和非公平锁，关于具体使用公平锁还是非公平锁，在创建ArrayBlockingQueue时可以指定，并且默认使用的是非公平锁。


4. ArrayBlockingQueue与Condition是组合关系，ArrayBlockingQueue中包含两个Condition对象(notEmpty和notFull)。而且，Condition又依赖于ArrayBlockingQueue而存在，通过Condition可以实现对ArrayBlockingQueue的更精确的访问

5. Condition的signal()，await()需要使用在lock,unlock之间才有效。
 

##### 重要属性
```
    /** The queued items */
    final Object[] items;

    /** items index for next take, poll, peek or remove */
    int takeIndex;// 下一个被取出元素的索引

    /** items index for next put, offer, or add */
    int putIndex;// 下一个被添加元素的索引

    /** Number of elements in the queue */
    //队列中元素的个数
    int count;

    /*
     * Concurrency control uses the classic two-condition algorithm
     * found in any textbook.
     */

    /** Main lock guarding all access */
    //主锁保护所有通道
    final ReentrantLock lock;

    /** Condition for waiting takes */
    private final Condition notEmpty;

    /** Condition for waiting puts */
    private final Condition notFull;
```

说明：
1. 前面类注释提到 Once created, the capacity cannot be  changed
  那items这个成员变量修饰符上应该有一个final修饰吧。关于final可以申明时赋值或者构造里赋值。那这个肯定是构造时赋的值了？？


##### 构造方法

一共有3个，这里说其中2个：

```
    public ArrayBlockingQueue(int capacity) {
        this(capacity, false);
    }

    /**
     * Creates an {@code ArrayBlockingQueue} with the given (fixed)
     * capacity and the specified access policy.
     *
     * @param capacity the capacity of this queue
     * @param fair if {@code true} then queue accesses for threads blocked
     *        on insertion or removal, are processed in FIFO order;
     *        if {@code false} the access order is unspecified.
     */
    public ArrayBlockingQueue(int capacity, boolean fair) {
        if (capacity <= 0)
            throw new IllegalArgumentException();
        //果然
        this.items = new Object[capacity];
        lock = new ReentrantLock(fair);//fair为true，表示是公平锁；fair为false，表示是非公平锁。
        notEmpty = lock.newCondition();//notEmpty和notFull是锁的两个Condition条件
        notFull =  lock.newCondition();
    }
 
```

说明：

1. Lock的作用是提供独占锁机制，来保护竞争资源；
2. Condition是为了更加精细的对锁进行控制，它依赖于Lock，通过某个条件对多线程进行控制。notEmpty表示“锁的非空条件”。当某线程想从队列中取数据时，而此时又没有数据，则该线程通过notEmpty.await()进行等待；当其它线程向队列中插入了元素之后，就调用notEmpty.signal()唤醒“之前通过notEmpty.await()进入等待状态的线程”。
同理，notFull表示“锁的满条件”。当某线程想向队列中插入元素，而此时队列已满时，该线程等待；当其它线程从队列中取出元素之后，就唤醒该等待的线程。


- (01)若某线程(线程A)要取数据时，数组正好为空，则该线程会执行notEmpty.await()进行等待；当其它某个线程(线程B)向数组中插入了数据之后，会调用notEmpty.signal()唤醒“notEmpty上的等待线程”。此时，线程A会被唤醒从而得以继续运行。

- (02)若某线程(线程H)要插入数据时，数组已满，则该线程会它执行notFull.await()进行等待；当其它某个线程(线程I)取出数据之后，会调用notFull.signal()唤醒“notFull上的等待线程”。此时，线程H就会被唤醒从而得以继续运行。


接下来看类注释中提到的方法put,take

##### put

```
    public void put(E e) throws InterruptedException {
        // 创建插入的元素是否为null，是的话抛出NullPointerException异常
        checkNotNull(e);
        // 获取“该阻塞队列的独占锁”
        final ReentrantLock lock = this.lock;
        // 获取“锁”，若当前线程是中断状态，则抛出InterruptedException异常
        lock.lockInterruptibly();
        try {
            // 若“队列为满”，则一直等待。
            while (count == items.length)
                notFull.await();
            enqueue(e);// 如果队列未满，则插入e。
        } finally {
           // 释放“锁”
            lock.unlock();
        }
    }
    
    private void enqueue(E x) { 
        final Object[] items = this.items;
        // 将x添加到”队列“中
        items[putIndex] = x;
        // 设置”下一个被取出元素的索引“
        //若++putIndex的值等于“队列的长度”，即添加元素之后，队列满；则设置“下一个被添加元素的索引”为0。
        if (++putIndex == items.length)
            putIndex = 0;
        // 将”队列中的元素个数”+1
        count++;
         // 唤醒notEmpty上的等待线程
        notEmpty.signal();
    }
```

##### take
```
    public E take() throws InterruptedException {
        // 获取“该阻塞队列的独占锁”
        final ReentrantLock lock = this.lock;
        // 获取“锁”，若当前线程是中断状态，则抛出InterruptedException异常
        lock.lockInterruptibly();
        try { // 若“队列为空”，则一直等待。
            while (count == 0)
                notEmpty.await();
            return dequeue();// 取出元素
        } finally {
           // 释放“锁”
            lock.unlock();
        }
    }
    
    private E dequeue() { 
        final Object[] items = this.items;
        
         // 强制将元素转换为“泛型E”
        @SuppressWarnings("unchecked")
        E x = (E) items[takeIndex];
        
        // 将第takeIndex元素设为null，即删除。同时，帮助GC回收。
        items[takeIndex] = null;
        // 设置“下一个被取出元素的索引”
        //若++takeIndex的值等于“队列的长度”，即取出元素之后，队列空；则设置“下一个被取出元素的索引”为0。
        if (++takeIndex == items.length)
            takeIndex = 0;
            
        // 将“队列中元素数量”-1
        count--;
        if (itrs != null)
            itrs.elementDequeued();//同时更新迭代器中的元素数据，这个什么时候需要呢？
            
        // 唤醒notFull上的等待线程。    
        notFull.signal();
        return x;
    }
```
 


至此，我们从类注释上该了解的内容就是这些了。。

![](http://pi42kejq1.bkt.clouddn.com/201811132245_977.png?markdown/)

[画图工具]https://www.processon.com/i/5aff9239e4b0ad442889145d
