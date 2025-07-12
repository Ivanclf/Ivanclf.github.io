---
title: 面向对象 - 继承与多态
date: 2024-04-24 19:37:59
tags: [Java, 面向对象, cpp]
---

继承与多态是面向对象中类管理最核心的部分之一，Java和C++在这方面的处理有着更大的差别。

## 继承

### Java

Java继承类的一般格式为

```java
class parent {
    ...
}

class child extends parent {
    ...
}
```

Java中类的继承有以下特征：

* Java中只支持继承一个类（但接口可以调用多个）。
* 重写时，直接写上和父类中对应方法一个名字和参数值的方法就行。
* 要访问父类的方法或者构造方法时，使用super关键字。
* 父类的私有成员（private和包外的default）不能被访问。
* class前有关键字final修饰时不能被被继承，方法前有关键字final时不能被重写。

Java还提供抽象类，适用于多个相关类有共同基础代码且需扩展场景的情况。

```java
abstract class A {
    abstract void f1();

    void f2() {
        ...
    }
} 
```

具有以下特征：

* 本质上也是类，只是多个类的共同父类，因此也可以用权限修饰符，也有构造方法（用于子类实例化时初始化成员变量），子类也只能继承一个抽象类。
* 抽象类自身不能被实例化。
* 抽象类可以带抽象方法（没有实现，子类必须重写），也可以有具体实现。

Java还提供比抽象类更为抽象的接口，适用于定义规范和契约，适应多实现的解耦场景。

```java
interface B {
    public void f1();
    public void f2();
}

class A implements B {
    ...
}
```

具有以下特征：

* 在Java8前，接口方法全抽象，不能有实现。Java8后可有默认实现（用default修饰）和静态方法。

* 接口无构造函数，成员变量默认为public static final。

* 接口可以多重实现，使用的关键字为implements而非extends。

### C++

C++继承的一般格式为

```cpp
class base1 {
    ...
};

class base2 {
    ...
};

class derived : public base1, public base2 {
    ...
};
```

特征如下

* 继承方式有3种：公有继承（public）、保护继承（protected）和私有继承（private），需要在继承的类前指明

    |继承方式|公有成员|受保护成员|私有成员|
    |-|-|-|-|
    |`public`|`public`|`protected`|无法访问|
    |`protected`|`protected`|`protected`|无法访问|
    |`private`|`private`|`private`|无法访问|

    {% note info %}
    在private继承时，其private方式是对于外而言的，类内仍然可以访问基类中的public和protected成员。因此private继承和protected继承在效果上差距不是很大（在三次继承时会有差别）。
    {% endnote %}

* 支持多重继承。当两个基类有同名成员时，需要显式指定基类名。

* 重写较为复杂，需要在基类中使用`virtual`关键字声明方法。

    ```cpp
    class Base {
    public:
        virtual void f() {
            ...
        }
    };

    class Derived : public Base {
    public:
        void display() override {
            ...
        }
    };
    ```

    {% note info %}
    从C++11开始，可以使用override关键字明确表示该方法是在重写基类的方法。算是对没有Java那样的特殊注解的一种补偿吧。
    {% endnote %}

* 若需要调用重写前的方法，需要显式指定基类名。

* 也支持抽象类，需要每一个方法都有virtual修饰

    ```cpp
    class A {
    public:
        virtual void f() = 0
    }
    ```

## 多态

多态可以理解为对某方法在多个类中的多次重写。在Java中直接在多个子类中重写即可，C++中也需要在基类中使用virtual关键字声明虚函数。换句话说，Java中的每一个方法都可以看作是虚函数。