---
title: 面向对象 - 基本语法
date: 2024-04-24 19:23:03
tags: [Java, 面向对象, cpp]
---

在一年前上Java课程的时候这里只有Java部分，现在学校用C++上oop这门课程，因此这里面向对象系列也变成了两种语言对oop处理的异同。

Java和C++均支持面向对象的编程方法，但二者在实现层面存在较大的区别。总的来说，Java更加简洁，对对象的操作更为彻底，更多是对面向对象这个概念的完全实现。而C++脱胎于C，本身即具有较高的灵活性，而面向对象只是其庞大语法特性中的一部分。

## 初始化

Java中的文件名必须与public类名一致，且一个文件只能有一个public类。类的声明必须在同一个文件中。换句话说，一个Java文件就是一个对象化的容器，承载着实现其功能的所有数据与方法。

```java
public class A {
    public A () { ... }
}
```

而C++中没有这些要求。一般而言，类的声明通常放在头文件，方法的实现放在对应的源文件，一个文件放一个类的说明内容，放什么类，并没有明确规定。而构造方法也允许默认参数。

在头文件中的内容（为正常高亮显示，这里仍然是cpp而非hpp，但这段在h或hpp上写并没有问题）

```cpp
class A {
public:
    A() : {}
    int add();
private:
    int x, y;
};
```

在实现中的内容

```cpp
int A::add() { return x + y; }
```

## 内存管理

Java中的内存管理较为简单，所有的对象都分配在堆上，自动管理内存，会自动清理不用的内存。

```java
A a = new A()
```

C++继承了C语言中 **优秀** 的手动管理内存的传统，对象分配在栈或者堆上都可以，但分配在堆上的对象需要手动释放资源，以免造成内存泄漏。释放内存是通过析构函数`~A()`或者使用`delete`关键字实现的

```cpp
A a;    // 栈对象，在函数进行结束后自行销毁
A *a = new A;  // 堆对象，需要手动delete
```

Java中很少存在指针的概念，引用也可以直接指代整个对象，但C++中new出来的对象实例会返回指向该对象的指针，而非该对象本身，C++在这方面分得很清楚。

## 权限

Java有4种权限：`public` `private` `default`（不加修饰符） `protected`，可以修饰类和其中的数据与方法，它们的区别如下

|访问修饰符|类的访问权限|方法的访问权限|
|-|-|-|
|`public`|可以在任何地方被访问|可以在任何地方被访问|
|`protected`|不能用于类|可以被同一个包中的类和不同包中的子类访问|
|`default`|只能被同一个包中的类访问|只能被同一包中的类访问|
|`private`|不能用于类|只能被同一类中的方法访问|

C++有3种权限：`public` `private` `protected`，只能修饰类中的数据和方法，他们的区别如下

|访问修饰符|类的访问权限|
|-|-|
|`public`|可以在任何地方被访问|
|`private`|只有在类内部被访问|
|`protected`|类内部和以公有继承的方式继承的子类（派生类）被访问|

然而C++提供了友元，可以用来破坏其封装性

```cpp
class A {
private:
    int value;
public:
    friend class displayValue(const A& obj);
};

class friendClass {
public:
    int displayValue(const A& obj) {
        return obj.value;
    }
};
```

Java中更多的修饰是与其更多的包管理状态相匹配的（package包，还有Java bean等），在项目管理方面具有巨大优势；而C++则比较灵活。

## 运算符重载

Java中除了`String`的`+`操作（用得太多太多了）外，其余均不支持运算符重载，相关操作均通过方法实现。这也是Java看着又臭又长的一个重要原因。

C++允许进行运算符重载，除了部分字符（`::` `.` `.*` `?:` `sizeof` `typeid`）外的很多字符都支持重载。

```cpp
class complex {
private:
    double re, im;
public:
    complex (double r, double i) : re(r), im(i) {}
    complex operator+ (complex c);
    complex operator* (complex c);
};
```

## 静态成员

Java的静态成员直接在类内初始化，而C++中的静态成员必需在类外单独定义。