import hscript.Macro;
import haxe.unit.*;

class Test extends TestCase {
	function assertScript(x,v:Dynamic,?vars : Dynamic,allowTypes=false) {
		var p = new hscript.Parser();
		p.allowTypes = allowTypes;
		var program = p.parseString(x);
		var bytes = hscript.Bytes.encode(program);
		program = hscript.Bytes.decode(bytes);
		var interp = new hscript.Interp();
		if( vars != null )
			for( v in Reflect.fields(vars) )
				interp.variables.set(v,Reflect.field(vars,v));
		var ret : Dynamic = interp.execute(program);
		assertEquals(v, ret);
	}

	function test():Void {
		assertScript("0",0);
		assertScript("0xFF", 255);
		#if !(php || python)
			#if haxe3
			assertScript("0xBFFFFFFF", 0xBFFFFFFF);
			assertScript("0x7FFFFFFF", 0x7FFFFFFF);
			#elseif !neko
			assertScript("n(0xBFFFFFFF)", 0xBFFFFFFF, { n : haxe.Int32.toNativeInt });
			assertScript("n(0x7FFFFFFF)", 0x7FFFFFFF, { n : haxe.Int32.toNativeInt } );
			#end
		#end
		assertScript("-123",-123);
		assertScript("- 123",-123);
		assertScript("1.546",1.546);
		assertScript(".545",.545);
		assertScript("'bla'","bla");
		assertScript("null",null);
		assertScript("true",true);
		assertScript("false",false);
		assertScript("1 == 2",false);
		assertScript("1.3 == 1.3",true);
		assertScript("5 > 3",true);
		assertScript("0 < 0",false);
		assertScript("-1 <= -1",true);
		assertScript("1 + 2",3);
		assertScript("~545",-546);
		assertScript("'abc' + 55","abc55");
		assertScript("'abc' + 'de'","abcde");
		assertScript("-1 + 2",1);
		assertScript("1 / 5",0.2);
		assertScript("3 * 2 + 5",11);
		assertScript("3 * (2 + 5)",21);
		assertScript("3 * 2 // + 5 \n + 6",12);
		assertScript("3 /* 2\n */ + 5",8);
		assertScript("[55,66,77][1]",66);
		assertScript("var a = [55]; a[0] *= 2; a[0]",110);
		assertScript("x",55,{ x : 55 });
		assertScript("var y = 33; y",33);
		assertScript("{ 1; 2; 3; }",3);
		assertScript("{ var x = 0; } x",55,{ x : 55 });
		assertScript("o.val",55,{ o : { val : 55 } });
		assertScript("o.val",null,{ o : {} });
		assertScript("var a = 1; a++",1);
		assertScript("var a = 1; a++; a",2);
		assertScript("var a = 1; ++a",2);
		assertScript("var a = 1; a *= 3",3);
		assertScript("a = b = 3; a + b",6);
		assertScript("add(1,2)",3,{ add : function(x,y) return x + y });
		assertScript("a.push(5); a.pop() + a.pop()",8,{ a : [3] });
		assertScript("if( true ) 1 else 2",1);
		assertScript("if( false ) 1 else 2",2);
		assertScript("var t = 0; for( x in [1,2,3] ) t += x; t",6);
		assertScript("var a = new Array(); for( x in 0...5 ) a[x] = x; a.join('-')","0-1-2-3-4");
		assertScript("(function(a,b) return a + b)(4,5)",9);
		assertScript("var y = 0; var add = function(a) y += a; add(5); add(3); y", 8);
		assertScript("var a = [1,[2,[3,[4,null]]]]; var t = 0; while( a != null ) { t += a[0]; a = a[1]; }; t",10);
		assertScript("var t = 0; for( x in 1...10 ) t += x; t", 45);
		#if haxe3
		assertScript("var t = 0; for( x in new IntIterator(1,10) ) t +=x; t", 45);
		#else
		assertScript("var t = 0; for( x in new IntIter(1,10) ) t +=x; t", 45);
		#end
		assertScript("var x = 1; try { var x = 66; throw 789; } catch( e : Dynamic ) e + x",790);
		assertScript("var x = 1; var f = function(x) throw x; try f(55) catch( e : Dynamic ) e + x",56);
		assertScript("var i=2; if( true ) --i; i",1);
		assertScript("var i=0; if( i++ > 0 ) i=3; i",1);
		assertScript("var a = 5/2; a",2.5);
		assertScript("{ x = 3; x; }", 3);
		assertScript("{ x : 3, y : {} }.x", 3);
		assertScript("function bug(){ \n }\nbug().x", null);
		assertScript("1 + 2 == 3", true);
		assertScript("-2 == 3 - 5", true);
		assertScript("var x=-3; x", -3);
		assertScript("var a:Array<Dynamic>=[1,2,4]; a[2]", 4, null, true);
		assertScript("/**/0", 0);
		assertScript("x=1;x*=-2", -2);
		
		// Test propertyNotFound
    var p1 = "dynamic property [p1]";
    var p21 = "dynamic nested property [p21]";
    var p3 = "dynamic nested property from call [p3]";
    
    var m1 = "dynamic call [m1]";
    var m21 = "dynamic nested call [m21]";
    var m3 = "dynamic nested call from property [m3]";
    
    var vars = 
    {
      f: function(v) {return 'argument received: $v'; },
      propertyNotFound: function(p, err)
      {
        var r: Dynamic = null;
        if(p == 'p1')
          r = p1;
        else if(p == 'p2')
          r = { p21: p21, m3: function() return m3 };
        else if(p == 'm1')
          r = function() return m1;
        else if(p == 'm2')
          r = function() return { m21: function() return m21, p3: p3 };
        else if(p == 'mp1')
          r = function(v) return 'dynamic call [mp1] with arguments [$v]';
        else if(p == 'mp2')
          r = function(v1, v2) return 'dynamic call [mp1] with arguments [$v1, $v2]';
        else
          err();
        return r;
      }
    };
       
    assertScript("p1", p1, vars);
    assertScript("p2.p21", p21, vars);
    assertScript("f(p1)", 'argument received: $p1', vars);

    assertScript("m1()", m1, vars);
    assertScript("m2().m21()", m21, vars);
    assertScript("p2.m3()", m3, vars);
    assertScript("m2().p3", p3, vars);
    
    assertScript("mp1(p1)", 'dynamic call [mp1] with arguments [$p1]', vars);
    assertScript("mp1(m1())", 'dynamic call [mp1] with arguments [$m1]', vars);
    assertScript("mp2(p1, m1())", 'dynamic call [mp1] with arguments [$p1, $m1]', vars);
	}

	static function main() {
		var runner = new TestRunner();
		runner.add(new Test());
		var succeed = runner.run();
		#if sys
			Sys.exit(succeed ? 0 : 1);
		#elseif flash
			flash.system.System.exit(succeed ? 0 : 1);
		#else
			if (!succeed)
				throw "failed";
		#end
	}

}