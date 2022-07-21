---
title: "手写springmvc实践"
discriptions: "手写springmvc实践"
date: 2019-04-28T11:23:34+08:00
author: Pismery Liu
archives: "2019"
tags: [Java,Spring]
categories: [Java]
showtoc: true
---

<!--more--> 
# Spring MVC

Spring MVC 中核心关键类是 DispatchServlet, 所有的请求都会通过这个类进行分派调用指定的业务逻辑代码；这个类中最重要的两个入口方法是 initStrategies() 和 doDispatch()

## DispatchServlet.initStrategies()

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190427225418.png)

从上图继承关系，可以发现 DispatchServlet 其实就是一个 HttpServlet；在 Web 容器初始化过程中，会自动调用 HttpServlet.init() 方法，下面看看 DispatchServlet 中 init 方法的大致调用；（spring-webmvc-5.1.4 版本）

```Java
// HttpServletBean
@Override
public final void init() throws ServletException {

	// Set bean properties from init parameters.
	PropertyValues pvs = new ServletConfigPropertyValues(getServletConfig(), this.requiredProperties);
	   
	...

	// Let subclasses do whatever initialization they like.
	initServletBean();
}

// FrameworkServlet
@Override
protected final void initServletBean() throws ServletException {
	...
	
	long startTime = System.currentTimeMillis();
	try {
		this.webApplicationContext = initWebApplicationContext();
		initFrameworkServlet();
	}
	catch (ServletException | RuntimeException ex) {
		logger.error("Context initialization failed", ex);
		throw ex;
	}
	
	...
}

// FrameworkServlet
protected WebApplicationContext initWebApplicationContext() {
	WebApplicationContext rootContext =
			WebApplicationContextUtils.getWebApplicationContext(getServletContext());
	WebApplicationContext wac = null;
	...

	if (!this.refreshEventReceived) {
		// Either the context is not a ConfigurableApplicationContext with refresh
		// support or the context injected at construction time had already been
		// refreshed -> trigger initial onRefresh manually here.
		synchronized (this.onRefreshMonitor) {
			onRefresh(wac);
		}
	}
    
    ...
	return wac;
}

// DispatchServlet
protected void onRefresh(ApplicationContext context) {
	initStrategies(context);
}

// DispacthServlet
protected void initStrategies(ApplicationContext context) {
	initMultipartResolver(context);
	initLocaleResolver(context);
	initThemeResolver(context);
	initHandlerMappings(context);
	initHandlerAdapters(context);
	initHandlerExceptionResolvers(context);
	initRequestToViewNameTranslator(context);
	initViewResolvers(context);
	initFlashMapManager(context);
}
```

上述代码简化时序图如下

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190428112442.png)


可以发现 DispacthServlet 最终调用了 initStrategies 方法，此方法就是初始化 SpringMVC 9 大组件的入口方法；

> SpringMVC 9 大组件

- MultipartResolver：文件上传解析
- LocaleResolver：国际化处理
- ThemeResolver：视图（View）解析
- HandlerMapping：解析 URL 获取 Handler
- HandlerAdapter：适配不同的 Handler
- HandlerExceptionResolver：异常处理解析
- RequestToViewNameTranslator：解析 Request 获取视图名称(ViewName)
- ViewResolver：通过 ViewName 和 Locale 信息解析获取相应的 View
- FlashMapManager：存储一个请求的结果至 FlashMap, 可用于重定向场景；


## DispatchServlet.doDispatch()

根据 J2EE 规范，我们知道 Http 请求分为 Get, Post, Put, Delete 请求;分别对应 HttpServlet 中的 doGet(), doPost, doPost, doDelete() 方法，下面我们看看 DispatchServlet 中是如何处理请求的; (spring-webmvc-5.1.4 版本)

```Java
// FrameworkServlet
@Override
protected final void doGet(HttpServletRequest request, HttpServletResponse response)
		throws ServletException, IOException {

	processRequest(request, response);
}
@Override
protected final void doPost(HttpServletRequest request, HttpServletResponse response)
		throws ServletException, IOException {

	processRequest(request, response);
}
@Override
protected final void doPut(HttpServletRequest request, HttpServletResponse response)
		throws ServletException, IOException {

	processRequest(request, response);
}
@Override
protected final void doDelete(HttpServletRequest request, HttpServletResponse response)
		throws ServletException, IOException {

	processRequest(request, response);
}


// FrameworkServlet
protected final void processRequest(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

    ...
    
    try {
    	doService(request, response);
    }
    catch (ServletException | IOException ex) {
    	failureCause = ex;
    	throw ex;
    }
    catch (Throwable ex) {
    	failureCause = ex;
    	throw new NestedServletException("Request processing failed", ex);
    }
    finally {
    	...
    }
}

// DispatchServlet
@Override
protected void doService(HttpServletRequest request, HttpServletResponse response) throws Exception {
	...

	try {
		doDispatch(request, response);
	}
	finally {
		if (!WebAsyncUtils.getAsyncManager(request).isConcurrentHandlingStarted()) {
			// Restore the original attribute snapshot, in case of an include.
			if (attributesSnapshot != null) {
				restoreAttributesAfterInclude(request, attributesSnapshot);
			}
		}
	}
}
```

上述代码简化时序图如下：

![](https://raw.githubusercontent.com/Pismery/Picture/master/img20190428154437.png)

从中可以发现，SpringMVC 中所有的请求最终都是会通过 DispatchServlet 中的 doDispatch 方法进行处理，下面大概讲解 doDispatch 大致处理逻辑；

```Java

// DispatchServlet
protected void doDispatch(HttpServletRequest request, HttpServletResponse response) throws Exception {
	HttpServletRequest processedRequest = request;
	HandlerExecutionChain mappedHandler = null;
	...

	try {
		ModelAndView mv = null;
		Exception dispatchException = null;

		try {
			...

			// Determine handler for the current request.
			mappedHandler = getHandler(processedRequest);
			if (mappedHandler == null) {
				noHandlerFound(processedRequest, response);
				return;
			}

			// Determine handler adapter for the current request.
			HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());

			...

			// Actually invoke the handler.
			mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
            
            ...
            // Set default Veiw Name
			applyDefaultViewName(processedRequest, mv);
			...
		}
		catch (Exception ex) {
			dispatchException = ex;
		}
		catch (Throwable err) {
			// As of 4.3, we're processing Errors thrown from handler methods as well,
			// making them available for @ExceptionHandler methods and other scenarios.
			dispatchException = new NestedServletException("Handler dispatch failed", err);
		}
		
		// Resolver the View
		processDispatchResult(processedRequest, response, mappedHandler, mv, dispatchException);
	}
	catch (Exception ex) {
		triggerAfterCompletion(processedRequest, response, mappedHandler, ex);
	}
	catch (Throwable err) {
		triggerAfterCompletion(processedRequest, response, mappedHandler,
				new NestedServletException("Handler processing failed", err));
	}
	finally {
		...
	}
}
```

从代码中可以看出，doDispatch 的执行逻辑大致有以下几步：

1. 获取 Request 相应的 Handler；
2. 获取 Request 相应的 HandlerAdpater;
3. 通过 HandlerAdpater 调用指定的 Handler 方法（即我们常写的 Controller 的指定某个方法）；并返回相应的 ModelAndView;
4. 通过 RequestToViewNameTranslator 设置默认 ViewName;
5. 通过 ViewResovle 解析获得 View;
6. 处理 View 信息返回客户端;

## 实现简单 SpringMVC 功能

上面讲述了 SpringMVC 的基本实现，其中关键的入口类是 DispatchServlet，在容器初始化时，会调用 DispatchServlet 中的 initStrategies 初始 9 大组件；每个请求都会经过 DispatchServlet 中的 doDispatch 方法；下面演示如何自己实现一个SpringMVC;

**( 项目 GitHub 地址：[https://github.com/Pismery/Pis-Spring-MVC.git](https://github.com/Pismery/Pis-Spring-MVC.git))**

```xml
<!-- web.xml -->
<web-app>
  <display-name>Archetype Created Web Application</display-name>

  <servlet>
    <servlet-name>PisSpringMVC</servlet-name>
    <servlet-class>org.pismery.mvc.PisDispatcherServlet</servlet-class>
    <init-param>
      <param-name>contextConfigLocation</param-name>
      <param-value>classpath:application.properties</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
  </servlet>


  <servlet-mapping>
    <servlet-name>PisSpringMVC</servlet-name>
    <url-pattern>/</url-pattern>
  </servlet-mapping>
</web-app>
```

```Java 
// DispacthServlet

public class PisDispatcherServlet extends HttpServlet {

    private PisHandlerMapping handlerMapping;
    private PisHandlerAdapter handlerAdapter;
    private List<ViewResolver> viewResolvers;

    @Override
    public void init() throws ServletException {
        // 初始化 Context
        PisApplicationContext context = new PisApplicationContext("/application.properties");
        // 文件上传
        initMultipartResolver(context);
        // 国际化
        initLocaleResolver(context);
        // View 解析
        initThemeResolver(context);
        // 解析url -> method
        initHandlerMappings(context);
        // 适配器
        initHandlerAdapters(context);
        // 异常处理
        initHandlerExceptionResolvers(context);
        // 从 request 中找到默认 viewName
        initRequestToViewNameTranslator(context);
        // 将 viewName 和 local (本地化信息) 解析成 View
        initViewResolvers(context);
        // 存储一个请求结果至 FlashMap ，可用于一个请求的输入是另一个请求的输出的场景；如重定向；
        initFlashMapManager(context);
    }
    
    private void initHandlerMappings(PisApplicationContext context) {
        this.handlerMapping = new PisUrlHandlerMapping(context);
    }

    private void initHandlerAdapters(PisApplicationContext context) {
        if (this.handlerMapping == null) {
            return;
        }
        this.handlerAdapter = new PisAnnotationHandlerAdapter();
    }

    private void initViewResolvers(PisApplicationContext context) {
        String templateRoot = context.getProperties().getProperty("templateRoot");
        String rootPath = this.getClass().getClassLoader().getResource(templateRoot).getFile();
        File rootDir = new File(rootPath);
        for (File templateFile : rootDir.listFiles()) {
            if (viewResolvers == null) {
                viewResolvers = new ArrayList<>();
            }

            viewResolvers.add(new PisViewResolver(templateFile.getName(), templateFile));
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        this.doPost(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doDispatch(req, resp);
    }

    /**
     * 所有请求的处理入口
     * @param req 请求
     * @param resp 响应
     * @throws IOException
     */
    private void doDispatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        //1. 根据 url 获取 handler;
        PisHandler handler = handlerMapping.getHandler(req);
        if (handler == null) {
            resp.getWriter().write("404 Pis No found!..");
        }
        //2. 通过 handler 调用目标方法；
        PisModelAndView mv = handlerAdapter.handle(req, resp, handler);

        if (mv == null || mv.getViewName() == null) {
            resp.getWriter().write("404 Pis No found!..");
            return;
        }

        //3. 解析 View，返回前端
        for (ViewResolver viewResolver : viewResolvers) {
            if (!mv.getViewName().equalsIgnoreCase(viewResolver.matchView())) {
                continue;
            }

            String parse = viewResolver.parse(mv);
            if (parse != null) {
                resp.getWriter().write(parse);
                break;
            }
        }
    }
}
```

