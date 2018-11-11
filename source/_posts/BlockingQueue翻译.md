---
title: BlockingQueue翻译
date: 2018-11-11 23:02:51
commentIssueId: 14
tags: 
  - jkd8
categories:
- 源码
---


 
#### 翻译
 
##### 类注释 
 
 ``` 
/**
 * A {@link java.util.Queue} that additionally supports operations
 * that wait for the queue to become non-empty when retrieving an
 * element, and wait for space to become available in the queue when
 * storing an element.
 
 * A Queue额外支持在检索元素时等待队列变为非空和
 在存储元素时等待队列中的空间变得可用的操作
 
 * {@code BlockingQueue} methods come in four forms, with different ways
 * of handling operations that cannot be satisfied immediately, but may be
 * satisfied at some point in the future:  
 
  BlockingQueue方法有四种形式，具有不同的操作方式，不能立即满足，但可能在将来的某个时间点满足
  
 * one throws an exception, the second returns a special value (either
 * {@code null} or {@code false}, depending on the operation), the third
 * blocks the current thread indefinitely until the operation can succeed,
 * and the fourth blocks for only a given maximum time limit before giving
 * up.  
 一个抛出异常，第二个返回一个特殊值（ null或false ，具体取决于操作），第三个程序将无限期地阻止当前线程，直到操作成功为止，
 而第四个程序块在放弃之前只有给定的最大时限。
  
 
 *
 * A {@code BlockingQueue} does not accept {@code null} elements.
 * Implementations throw {@code NullPointerException} on attempts
 * to {@code add}, {@code put} or {@code offer} a {@code null}.  A
 * {@code null} is used as a sentinel value to indicate failure of
 * {@code poll} operations.
 
  A BlockingQueue不接受null元素。 实现抛出NullPointerException上尝试add 
  put或offer一个null 。 A null用作哨兵值以指示poll操作失败。
 
 *
 * A {@code BlockingQueue} may be capacity bounded. At any given
 * time it may have a {@code remainingCapacity} beyond which no
 * additional elements can be {@code put} without blocking.
 * A {@code BlockingQueue} without any intrinsic capacity constraints always
 * reports a remaining capacity of {@code Integer.MAX_VALUE}.
 * 
   A BlockingQueue可能是容量有限的。 在任何给定的时间它可能有一个remainingCapacity超过其中没有额外的元素可以put没有阻止。 没有任何内在容量限制的A BlockingQueue总是报告剩余容量为Integer.MAX_VALUE 
   
   
 * {@code BlockingQueue} implementations are designed to be used
 * primarily for producer-consumer queues, but additionally support
 * the {@link java.util.Collection} interface.  So, for example, it is
 * possible to remove an arbitrary element from a queue using
 * {@code remove(x)}. However, such operations are in general
 * <em>not</em> performed very efficiently, and are intended for only
 * occasional use, such as when a queued message is cancelled.
 * 
   BlockingQueue实现被设计为主要用于生产者 - 消费者队列，但另外支持Collection接口。 因此，例如，可以使用remove(x)从队列中删除任意元素。 然而，这样的操作通常不能非常有效地执行，并且仅用于偶尔使用，例如当排队的消息被取消时。
 
 * {@code BlockingQueue} implementations are thread-safe.  All
 * queuing methods achieve their effects atomically using internal
 * locks or other forms of concurrency control. However, the
 * <em>bulk</em> Collection operations {@code addAll},
 * {@code containsAll}, {@code retainAll} and {@code removeAll} are
 * <em>not</em> necessarily performed atomically unless specified
 * otherwise in an implementation. So it is possible, for example, for
 * {@code addAll(c)} to fail (throwing an exception) after adding
 * only some of the elements in {@code c}.
 *
   BlockingQueue实现是线程安全的。 所有排队方法使用内部锁或其他形式的并发控制在原子上实现其效果。 然而， 大量的Collection操作addAll ， containsAll ， retainAll和removeAll 不一定原子除非在实现中另有规定执行。 因此有可能，例如，为addAll(c)到只增加一些元件在后失败（抛出异常） c 。
 
 
 * A {@code BlockingQueue} does <em>not</em> intrinsically support
 * any kind of &quot;close&quot; or &quot;shutdown&quot; operation to
 * indicate that no more items will be added.  The needs and usage of
 * such features tend to be implementation-dependent. For example, a
 * common tactic is for producers to insert special
 * <em>end-of-stream</em> or <em>poison</em> objects, that are
 * interpreted accordingly when taken by consumers.
 * 
   A BlockingQueue上不支持任何类型的“关闭”或“关闭”操作，表示不再添加项目。 这些功能的需求和使用往往依赖于实现。 例如，一个常见的策略是生产者插入特殊的尾流或毒物 ，这些消费者在被消费者摄取时被相应地解释
   
   
 *  
 * Usage example, based on a typical producer-consumer scenario.
 * Note that a {@code BlockingQueue} can safely be used with multiple
 * producers and multiple consumers.
 使用示例，基于典型的生产者 - 消费者场景。 请注意， BlockingQueue可以安全地与多个生产者和多个消费者一起使用。
 
 
 ```
<!-- more -->
   

##### 示例

```
 * class Producer implements Runnable {
 *   private final BlockingQueue queue;
 *   Producer(BlockingQueue q) { queue = q; }
 *   public void run() {
 *     try {
 *       while (true) { queue.put(produce()); }
 *     } catch (InterruptedException ex) { ... handle ...}
 *   }
 *   Object produce() { ... }
 * }
 *
 * class Consumer implements Runnable {
 *   private final BlockingQueue queue;
 *   Consumer(BlockingQueue q) { queue = q; }
 *   public void run() {
 *     try {
 *       while (true) { consume(queue.take()); }
 *     } catch (InterruptedException ex) { ... handle ...}
 *   }
 *   void consume(Object x) { ... }
 * }
 *
 * class Setup {
 *   void main() {
 *     BlockingQueue q = new SomeQueueImplementation();
 *     Producer p = new Producer(q);
 *     Consumer c1 = new Consumer(q);
 *     Consumer c2 = new Consumer(q);
 *     new Thread(p).start();
 *     new Thread(c1).start();
 *     new Thread(c2).start();
 *   }
 * }} 
 *
```



```   

 * Memory consistency effects: As with other concurrent
 * collections, actions in a thread prior to placing an object into a
 * {@code BlockingQueue}
 * <a href="package-summary.html#MemoryVisibility"><i>happen-before</i></a>
 * actions subsequent to the access or removal of that element from
 * the {@code BlockingQueue} in another thread.
 *
 * 存储器一致性效果：当与其他并发集合，事先将物体放置成在一个线程动作BlockingQueue
 
   happen-before到该元素的从访问或移除后续动作BlockingQueue在另一个线程。  
```



##### 源码

```
public interface BlockingQueue<E> extends Queue<E> {
    /**
     * Inserts the specified element into this queue if it is possible to do
     * so immediately without violating capacity restrictions, returning
     * {@code true} upon success and throwing an
     * {@code IllegalStateException} if no space is currently available.
     * When using a capacity-restricted queue, it is generally preferable to
     * use {@link #offer(Object) offer}.
     *
     * 将指定的元素插入此队列中，如果它是立即可行且不会违反容量限制，返回true在成功和抛出IllegalStateException如果当前没有空间可用。 当使用容量限制队列时，通常最好使用offer 。
     */
    boolean add(E e);

    /**
     * Inserts the specified element into this queue if it is possible to do
     * so immediately without violating capacity restrictions, returning
     * {@code true} upon success and {@code false} if no space is currently
     * available.  When using a capacity-restricted queue, this method is
     * generally preferable to {@link #add}, which can fail to insert an
     * element only by throwing an exception.
     *
     * 将指定的元素插入此队列中，如果它是立即可行且不会违反容量限制，返回true在成功和false ，如果当前没有空间可用。 当使用容量限制队列时，此方法通常优于add(E) ，这可能无法仅通过抛出异常来插入元素。
     */
    boolean offer(E e);

    /**
     * Inserts the specified element into this queue, waiting if necessary
     * for space to become available.
     *
     * 将指定的元素插入到此队列中，等待空间可用。
     */
    void put(E e) throws InterruptedException;

    /**
     * Inserts the specified element into this queue, waiting up to the
     * specified wait time if necessary for space to become available.
     *
     * 将指定的元素插入到此队列中，等待指定的等待时间（如有必要）才能使空间变得可用。
     */
    boolean offer(E e, long timeout, TimeUnit unit)
        throws InterruptedException;

    /**
     * Retrieves and removes the head of this queue, waiting if necessary
     * until an element becomes available.
     *
     * 检索并删除此队列的头，如有必要，等待元素可用。
     */
    E take() throws InterruptedException;

    /**
     * Retrieves and removes the head of this queue, waiting up to the
     * specified wait time if necessary for an element to become available.
     *
     * 检索并删除此队列的头，等待指定的等待时间（如有必要）使元素变为可用。
     */
    E poll(long timeout, TimeUnit unit)
        throws InterruptedException;

    /**
     * Returns the number of additional elements that this queue can ideally
     * (in the absence of memory or resource constraints) accept without
     * blocking, or {@code Integer.MAX_VALUE} if there is no intrinsic
     * limit.
     *
     返回该队列最好可以（在没有存储器或资源约束）接受而不会阻塞，或附加的元素的数量Integer.MAX_VALUE如果没有固有的限制。
     
     * <p>Note that you <em>cannot</em> always tell if an attempt to insert
     * an element will succeed by inspecting {@code remainingCapacity}
     * because it may be the case that another thread is about to
     * insert or remove an element.
     *
     *  请注意，您不能总是通过检查remainingCapacity来判断是否尝试插入元素，因为可能是另一个线程即将插入或删除元素的情况
     */
    int remainingCapacity();

    /**
     * Removes a single instance of the specified element from this queue,
     * if it is present.  More formally, removes an element {@code e} such
     * that {@code o.equals(e)}, if this queue contains one or more such
     * elements.
     * Returns {@code true} if this queue contained the specified element
     * (or equivalently, if this queue changed as a result of the call).
     *
     * 从该队列中删除指定元素的单个实例（如果存在）。 更正式地，删除一个元素e ，使得o.equals(e) ，如果这个队列包含一个或多个这样的元素。 如果此队列包含指定的元素（或等效地，如果此队列作为调用的结果而更改），则返回true 。
     */
    boolean remove(Object o);

    /**
     * Returns {@code true} if this queue contains the specified element.
     * More formally, returns {@code true} if and only if this queue contains
     * at least one element {@code e} such that {@code o.equals(e)}.
     *
     * 如果此队列包含指定的元素，则返回true 。 更正式地，返回true如果且仅当这个队列至少包含一个元素e ，使得o.equals(e) 。
     */
    public boolean contains(Object o);

    /**
     * Removes all available elements from this queue and adds them
     * to the given collection.  This operation may be more
     * efficient than repeatedly polling this queue.  A failure
     * encountered while attempting to add elements to
     * collection {@code c} may result in elements being in neither,
     * either or both collections when the associated exception is
     * thrown.  Attempts to drain a queue to itself result in
     * {@code IllegalArgumentException}. Further, the behavior of
     * this operation is undefined if the specified collection is
     * modified while the operation is in progress.
     *
     * 从该队列中删除所有可用的元素，并将它们添加到给定的集合中。 此操作可能比重复轮询此队列更有效。 尝试向集合c添加元素时遇到的c可能会导致在抛出关联的异常时，
     元素既不在两个集合中，也可能不是两个集合。 尝试将队列排入自身会导致IllegalArgumentException 。 此外，如果在操作进行中修改了指定的集合，则此操作的行为是未定义的。

     */
    int drainTo(Collection<? super E> c);

    /**
     * Removes at most the given number of available elements from
     * this queue and adds them to the given collection.  A failure
     * encountered while attempting to add elements to
     * collection {@code c} may result in elements being in neither,
     * either or both collections when the associated exception is
     * thrown.  Attempts to drain a queue to itself result in
     * {@code IllegalArgumentException}. Further, the behavior of
     * this operation is undefined if the specified collection is
     * modified while the operation is in progress.
     *
     * 最多从该队列中删除给定数量的可用元素，并将它们添加到给定的集合中。 尝试向集合c添加元素时遇到的c可能会导致在抛出关联的异常时，
     元素既不在两个集合中，也可能不是两个集合。 尝试将队列排入自身导致IllegalArgumentException 。 此外，如果在操作进行中修改了指定的集合，则此操作的行为是未定义的。

     */
    int drainTo(Collection<? super E> c, int maxElements);
}

 ```
    
#### 总结
1. 是一种线程安全的队列
1. 一般用于这样的场景：一个线程生产对象，另一个线程来消耗对象
1. 不能向BlockingQueue中插入null,否则会抛出NullPointerException异常
    

