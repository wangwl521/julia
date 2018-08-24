using Test

function test_exc_stack()
    # Basic exception stack handling
    try
        error("A")
    catch
        @test length(Base.catch_stack()) == 1
    end
    @test length(Base.catch_stack()) == 0
    try
        try
            error("A")
        finally
            @test length(Base.catch_stack()) == 1
        end
    catch
        @test length(Base.catch_stack()) == 1
    end
    # Errors stack up
    try
        error("RootCause")
    catch
        @test length(Base.catch_stack()) == 1
        try
            error("B")
        catch
            stack = Base.catch_stack()
            @test length(stack) == 2
            @test stack[1][1].msg == "RootCause"
            @test stack[2][1].msg == "B"
        end
        stack = Base.catch_stack()
        @test length(stack) == 1
        @test stack[1][1].msg == "RootCause"
    end
    # Lowering - value position
    val = try
        error("A")
    catch
        @test length(Base.catch_stack()) == 1
    end
    val
end

function test_exc_stack_tailpos()
    # exercise lowering code path for tail position
    try
        error("A")
    catch
        @test length(Base.catch_stack()) == 1
    end
end

# test that exception stack is correctly on return / break / goto
function test_exc_stack_catch_return()
    try
        error("A")
    catch
        @test length(Base.catch_stack()) == 1
        return
    end
end
function test_exc_stack_catch_break()
    for i=1:1
        try
            error("A")
        catch
            @test length(Base.catch_stack()) == 1
            break
        end
    end
    for i=1:1
        try
            error("A")
        catch
            @test length(Base.catch_stack()) == 1
            continue
        end
    end
    try
        error("A")
    catch
        @test length(Base.catch_stack()) == 1
        @goto outofcatch
    end
    @label outofcatch
end

function test_exc_stack_deep(n)
    # Generate deep exception stack with recursive handlers
    # Note that if you let this overflow the program stack (not the exception
    # stack) julia will crash. See #28577
    n != 1 || error("RootCause")
    try
        test_exc_stack_deep(n-1)
    catch
        error("n==$n")
    end
end

function test_exc_stack_yield()
    # Regression test for #12485
    try
        error("A")
    catch
        yield()
        @test length(Base.catch_stack()) == 1
    end
end

@testset "Exception stacks" begin
    test_exc_stack()
    test_exc_stack_tailpos()
    test_exc_stack_catch_return()
    @test length(Base.catch_stack()) == 0
    test_exc_stack_catch_break()
    try
        # FIXME!! Running this with n=1000 aborts with a memory error.
        # Likely due to the GC changes.
        test_exc_stack_deep(100)
    catch
        @test length(Base.catch_stack()) == 100
    end
    test_exc_stack_yield()
    @test length(Base.catch_stack()) == 0
end
