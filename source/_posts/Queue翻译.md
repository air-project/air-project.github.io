---
title: Queue翻译
date: 2018-11-11 18:14:24
commentIssueId: 13
tags: 
  - jkd8
categories:
- 源码
---
 
 
#### 翻译
 
##### 类注释 
 
 ``` 
A collection designed for holding elements prior to processing.
一个设计用来保存需要预先处理元素的Collection

Besides basic {@link java.util.Collection Collection} operations,
queues provide additional insertion, extraction, and inspection
operations.  
除了基本的 Collection操作,队列提供额外的插入、提取和检验操作

Each of these methods exists in two forms: one throws
an exception if the operation fails, the other returns a special
value (either {@code null} or {@code false}, depending on the
operation).  

这些方法中存在两种形式:
一个抛出一个异常,如果操作失败, 
另一个返回一个特殊的值( null或者 false,根据操作)


The latter form of the insert operation is designed
specifically for use with capacity-restricted {@code Queue}
implementations; 

后者的插入操作形式是专门为使用容量限制 Queue实现;

in most implementations, insert operations cannot  fail.

在大多数实现,insert操作不能失败。
```


<!-- more -->

##### 六个主要方法




method| Throws exception | Returns special value
---|---|---
Insert	|add(e)		|offer(e)
Remove	|remove()	|poll()
Examine	|element()	|peek()


  
```
Queues typically, but do not necessarily, order elements in a
FIFO (first-in-first-out) manner. 

队列通常,但不一定,顺序元素FIFO(先进先出)的方式

Among the exceptions are
priority queues, which order elements according to a supplied
comparator, or the elements' natural ordering, and LIFO queues (or
stacks) which order the elements LIFO (last-in-first-out).

例如在优先队列中,顺序元素根据提供的比较器,或者元素的自然顺序,后进先出队列顺序(或堆栈)后进先出的元素。
   
Whatever the ordering used, the <em>head</em> of the queue is that
element which would be removed by a call to {@link #remove() } or
{@link #poll()}.  In a FIFO queue, all new elements are inserted at
the <em>tail</em> of the queue. Other kinds of queues may use
different placement rules.  Every {@code Queue} implementation
must specify its ordering properties.

无论使用哪种顺序,队列的头部是元素将被调用remove()或poll()。在FIFO队列,所有新元素插入到队列的尾部。
其他类型的队列可能使用不同的放置规则。每个Queue实现必须指定其排序属性。

The {@link #offer offer} method inserts an element if possible,
otherwise returning {@code false}.  This differs from the {@link
java.util.Collection#add Collection.add} method, which can fail to
add an element only by throwing an unchecked exception.  The
{@code offer} method is designed for use when failure is a normal,
rather than exceptional occurrence, for example, in fixed-capacity
(or &quot;bounded&quot;) queues.

offer方法插入一个元素如果可能,否则返回false。
这不同于Collection.add方法,它可以不添加一个元素只有抛出未检测的异常。
offer方法是设计用于当失败是正常的,而不是特殊情况,例如,在固定电容(或“有界”)队列。


The {@link #remove()} and {@link #poll()} methods remove and
return the head of the queue.
Exactly which element is removed from the queue is a
function of the queue's ordering policy, which differs from
implementation to implementation. The {@code remove()} and
{@code poll()} methods differ only in their behavior when the
queue is empty: the {@code remove()} method throws an exception,
while the {@code poll()} method returns {@code null}.
 

remove()和poll()方法删除并返回队列的头部。从队列中删除哪些元素是一个函数队列的排序策略,这不同于实现来实现。
remove()和poll()方法不同队列为空时:remove()方法抛出一个异常,而poll()方法返回null。

The {@link #element()} and {@link #peek()} methods return, but do
not remove, the head of the queue.
element() peek()方法返回,但不要删除队列的头部。

The {@code Queue} interface does not define the <i>blocking queue
methods</i>, which are common in concurrent programming.  These methods,
which wait for elements to appear or for space to become available, are
defined in the {@link java.util.concurrent.BlockingQueue} interface, which
extends this interface.

Queue接口没有定义阻塞队列的方法,常见的并发编程。
这些方法,等待元素出现或空间可用BlockingQueue接口中定义,扩展这个接口。

{@code Queue} implementations generally do not allow insertion
of {@code null} elements, although some implementations, such as
{@link LinkedList}, do not prohibit insertion of {@code null}.
Even in the implementations that permit it, {@code null} should
not be inserted into a {@code Queue}, as {@code null} is also
used as a special return value by the {@code poll} method to
indicate that the queue contains no elements.

Queue null元素的实现通常不允许插入,尽管一些实现,如LinkedList、不禁止插入null。
即使在允许它的实现,null不应插入一个Queue null也用作特殊poll返回值的方法表明,队列中不包含任何元素。

{@code Queue} implementations generally do not define
element-based versions of methods {@code equals} and
{@code hashCode} but instead inherit the identity based versions
from class {@code Object}, because element-based equality is not
always well-defined for queues with the same elements but different
ordering properties.

Queue实现通常不定义的元素版本方法equals hashCode而是继承类Object的基于身份的版本,
因为元素相同的平等并不总是明确的队列元素但不同排序属性。
 ```


##### 源码 
 
 
 
 ```
public interface Queue<E> extends Collection<E> {
	/**
	 * Inserts the specified element into this queue if it is possible to do so
	 * immediately without violating capacity restrictions, returning
	 * {@code true} upon success and throwing an {@code IllegalStateException}
	 * if no space is currently available.
	 * 将指定的元素插入此队列能否立即这样做,在不违反容量限制,返回 true成功
	   和抛出 IllegalStateException如果没有目前可用的空间
	 */
	boolean add(E e);

	/**
	 * Inserts the specified element into this queue if it is possible to do
	 * so immediately without violating capacity restrictions.
	 * When using a capacity-restricted queue, this method is generally
	 * preferable to {@link #add}, which can fail to insert an element only
	 * by throwing an exception.
	 * 将指定的元素插入此队列能否立即这样做,在不违反容量限制。
	   使用capacity-restricted队列时,这种方法通常比 add(E),无法插入一个元素只有通过抛出异常。
	 */
	boolean offer(E e);

	/**
	 * Retrieves and removes the head of this queue.  This method differs
	 * from {@link #poll poll} only in that it throws an exception if this
	 * queue is empty.
	 * 检索并删除此队列的头。这个方法与 poll唯一的不同之处在于,它将抛出一个异常,如果这个队列是空的。
	 */
	E remove();

	/**
	 * Retrieves and removes the head of this queue,
	 * or returns {@code null} if this queue is empty.
	 * 检索并删除此队列的头,或者返回 null如果这个队列是空的。
	 */
	E poll();

	/**
	 * Retrieves, but does not remove, the head of this queue.  This method
	 * differs from {@link #peek peek} only in that it throws an exception
	 * if this queue is empty.
	 * 检索,但不删除此队列的头。这个方法与 peek唯一的不同之处在于,它将抛出一个异常,如果这个队列是空的。
	 */
	E element();

	/**
	 * Retrieves, but does not remove, the head of this queue,
	 * or returns {@code null} if this queue is empty.
	 * 检索,但不删除此队列的头,或者返回 null如果这个队列是空的。
	 */
	E peek();
}
 ```
    
#### 总结
1. 队列是什么？就是用来装一组元素的集合
1. 队列并不都是FIFO
1. 队列并不提供阻塞（由子类实现)
1. 队列可以指定容量
1. 一类抛异常一类为不抛
    

