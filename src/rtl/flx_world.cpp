#include "flx_world.hpp"
#include "flx_eh.hpp"
#include "flx_ts_collector.hpp"
#include "flx_rtl.hpp"

using namespace ::std;
using namespace ::flx::rtl;
using namespace ::flx::pthread;
using namespace ::flx::run;

namespace flx { namespace run {

// terminates process!
// Not called by default (let the OS clean up)

static int do_final_cleanup(
  bool debug_driver,
  flx::gc::generic::gc_profile_t *gcp,
  flx_dynlink_t *library,
  flx_libinst_t *instance
)
{
  flx::gc::generic::collector_t *collector = gcp->collector;

  // garbage collect application objects
  {
    if (debug_driver || gcp->debug_collections)
      fprintf(stderr, "[do_final_cleanup] Finalisation: pass 1 Data collection starts ..\n");

    unsigned long n = collector->collect();
    unsigned long a = collector->get_allocation_count();

    if (debug_driver || gcp->debug_collections)
      fprintf(stderr, "[do_final_cleanup] flx_run collected %ld objects, %ld left\n", n, a);
  }

  // garbage collect system objects
  {
    if (debug_driver || gcp->debug_collections)
      fprintf(stderr, "[do_final_cleanup] Finalisation: pass 2 Final collection starts ..\n");

    collector->free_all_mem();
    unsigned long a = collector->get_allocation_count();

    if (debug_driver || gcp->debug_collections)
      fprintf(stderr, "[do_final_cleanup] Remaining %ld objects (should be 0)\n", a);

    if (a != 0){
      fprintf(stderr, "[do_final_cleanup] flx_run %ld uncollected objects, should be zero!! return code 5\n", a);
      return 5;
    }
  }

  if (debug_driver)
    fprintf(stderr, "[do_final_cleanup] exit 0\n");

  return 0;
}

// RUN A FELIX INSTANCE IN THE CURRENT PTHREAD
//
// CURRENTLY ONLY CALLED ONCE IN MAIN THREAD

static void *get_stack_pointer() { void *x=(void*)&x; return x; }

std::list<fthread_t*>*
run_felix_pthread_ctor(
  flx::gc::generic::gc_profile_t *gcp,
  flx_libinst_t *instance)
{
  //fprintf(stderr, "run_felix_pthread -- the MAIN THREAD\n");
  flx::gc::generic::collector_t *collector = gcp->collector;
  std::list<fthread_t*> *active = new std::list<fthread_t*>;

  {
    con_t *top = instance->main_proc;
    if (top)
    {
      fthread_t *flx_main = new (*gcp, _fthread_ptr_map, false) fthread_t(top);
      collector->add_root(flx_main);
      active->push_front(flx_main);
    }
  }

  {
    con_t *top = instance->start_proc;
    if (top)
    {
      fthread_t *ft = new (*gcp, _fthread_ptr_map, false) fthread_t(top);
      collector->add_root(ft);
      active->push_front(ft);
    }
  }
  return active;
}

void run_felix_pthread_dtor(
  bool debug_driver,
  flx::gc::generic::gc_profile_t *gcp,
  flx::pthread::thread_control_t *thread_control,
  flx_dynlink_t *library,
  flx_libinst_t *instance
)
{
  if (debug_driver)
    fprintf(stderr, "[run_felix_pthread_dtor] MAIN THREAD FINISHED: waiting for other threads\n");

  thread_control->join_all();

  if (debug_driver) 
    fprintf(stderr, "[run_felix_pthread_dtor] ALL THREADS DEAD: mainline cleanup!\n");

  if (debug_driver) {
    flx::gc::generic::collector_t *collector = gcp->collector;

    unsigned long uncollected = collector->get_allocation_count();
    unsigned long roots = collector->get_root_count();
    fprintf(stderr,
      "[run_felix_pthread_dtor] program finished, %ld collections, %ld uncollected objects, roots %ld\n",
      gcp->collections, uncollected, roots);
  }
  gcp->collector->remove_root(instance);

  if (gcp->finalise)
    (void)do_final_cleanup(debug_driver, gcp, library, instance);

  if (debug_driver) 
    fprintf(stderr, "[run_felix_pthread_dtor] mainline cleanup complete, exit\n");
   
}

// construct from flx_config pointer
flx_world::flx_world(flx_config *c_arg) : c(c_arg) {}

int flx_world::setup(int argc, char **argv) {
  int res;
  if((res = c->init(argc, argv) != 0)) return res;

  debug = c->debug;
  if(debug)
    fprintf(stderr, "[flx_world: setup]\n");
  debug_driver = c->debug_driver;

  if(debug)
    fprintf(stderr, "[flx_world: setup] Created allocator\n");
  allocator = new flx::gc::collector::malloc_free();
  allocator->set_debug(c->debug_allocations);

  // previous direct ctor scope ended at closing brace of FLX_MAIN
  // but delete can probably be moved up after collector delete (also used by explicit_dtor)
  thread_control = new flx::pthread::thread_control_t(c->debug_threads);
  if(debug)
    fprintf(stderr, "[flx_world: setup] Created thread control object\n");

  // NB: !FLX_SUPPORT_ASYNC refers to async IO, hence ts still needed thanks to flx pthreads
  collector = new flx::gc::collector::flx_ts_collector_t(allocator, thread_control);
  collector->set_debug(c->debug_collections);
  if(debug)
    fprintf(stderr, "[flx_world: setup] Created ts collector\n");

  gcp = new flx::gc::generic::gc_profile_t(
    c->debug_driver,
    c->debug_allocations,
    c->debug_collections,
    c->report_collections,
    c->allow_collection_anywhere,
    c->gc_freq,
    c->min_mem,
    c->max_mem,
    c->free_factor,
    c->finalise,
    collector
  );

  if(debug)
    fprintf(stderr, "[flx_world: setup] Created gc profile object\n");

  library = c->link_library(c,gcp);
  collector->add_root (library);

  if(debug)
    fprintf(stderr, "[flx_world: setup] Created library object\n");

  if (debug_driver)
    fprintf(stderr, "[flx_world:setup] flx_run driver begins %s\n", c->flx_argv[0]);

  // flx_libinst_t::create can run code, so add thread to avoid world_stop abort
  thread_control->add_thread(get_stack_pointer());

  // Create the usercode driver instance
  // NB: seems to destroy()ed in do_final_cleanup
  instance = new (*gcp, flx_libinst_ptr_map, false) flx_libinst_t(debug_driver);
  collector->add_root(instance);
  instance->create(
    library,
    gcp,
    c->flx_argc,
    c->flx_argv,
    stdin,
    stdout,
    stderr,
    debug_driver);

  thread_control->remove_thread();

  if (debug_driver) {
    fprintf(stderr, "[flx_world:setup] loaded library %s at %p\n", c->filename, library->library);
    fprintf(stderr, "[flx_world:setup] thread frame at %p\n", instance->thread_frame);
    fprintf(stderr, "[flx_world:setup] initial continuation at %p\n", instance->start_proc);
    fprintf(stderr, "[flx_world:setup] main continuation at %p\n", instance->main_proc);
    fprintf(stderr, "[flx_world:setup] creating async scheduler\n");
  }

  async_scheduler = new async_sched(
    this,
    debug_driver,
    gcp,
    run_felix_pthread_ctor(gcp, instance),
    thread_control); // deletes active for us!

  return 0;
}

int flx_world::explicit_dtor()
{
  if (debug_driver)
    fprintf(stderr, "[explicit_dtor] entry\n");

  run_felix_pthread_dtor(debug_driver, gcp, thread_control, library, instance);

  if (gcp->finalise)
  {
    if (debug_driver)
      fprintf(stderr, "[explicit_dtor] flx_run driver ends with finalisation complete\n");
  }
  else
  {
    if (debug_driver || gcp->debug_collections)
    {
      unsigned long a = gcp->collector->get_allocation_count();
      fprintf(stderr,
        "[explicit_dtor] flx_run driver ends with finalisation skipped, %ld uncollected "
          "objects\n", a);
    }
  }

  if (debug_driver)
    fprintf(stderr, "[explicit_dtor] exit 0\n");

  return 0;
}

int flx_world::teardown() {
  if (debug_driver)
    fprintf(stderr, "[teardown] entry\n");

  thread_control -> add_thread(get_stack_pointer());

  delete async_scheduler;

  if (debug_driver)
    fprintf(stderr, "[teardown] deleted async_scheduler\n");


  // could this override error_exit_code if something throws?
  int error_exit_code = explicit_dtor();
  if (debug_driver)
    fprintf(stderr,"[teardown] explicit dtor run code %d\n", error_exit_code);

  instance=0;
  library=0;
  if (debug_driver)
    fprintf(stderr,"[teardown] library & instance NULLED\n");

  // And we're done, so start cleaning up.
  delete gcp;

  delete collector;
  if (debug_driver) 
    fprintf(stderr,"[teardown] collector deleted\n");

  delete allocator;
  if (debug_driver) 
    fprintf(stderr,"[teardown] allocator deleted\n");

  if (debug_driver) 
    fprintf(stderr, "[teardown] flx_run driver ends code=%d\n", error_exit_code);

  delete thread_control;  // RF: cautiously delete here
  if (debug_driver) 
    fprintf(stderr,"[teardown] thread control deleted\n");
  return error_exit_code;
}

void flx_world::begin_flx_code() {
  thread_control->add_thread(get_stack_pointer());
}

void flx_world::end_flx_code() {
  thread_control->remove_thread();
}

// returns number of pending operations scheduled by svc_general
// return error code < 0 otherwise
// catches all known exceptions
//
int flx_world::run_until_blocked() {
  // this may not be called on the same thread, so let thread control know
  // when we exit, main thread is not running so pthreads can garbage collect without waiting for us

  try {
    return async_scheduler->prun(async_sched::ret);
  }
  catch (flx_exception_t &x) { return - flx_exception_handler (&x); }
  catch (std::exception &x) { return - std_exception_handler (&x); }
  catch (int &x) { fprintf (stderr, "Exception type int: %d\n", x); return -x; }
  catch (::std::string &x) { fprintf (stderr, "Exception type string : %s\n", x.c_str()); return -1; }
  catch (::flx::rtl::con_t &x) { fprintf (stderr, "Rogue continuatiuon caught\n"); return -6; }
  catch (...) { fprintf(stderr, "[flx_world:run_until_blocked] Unknown exception in thread!\n"); return -5; }
}

int flx_world::run_until_complete () {
  // this may not be called on the same thread, so let thread control know
  // when we exit, main thread is not running so pthreads can garbage collect without waiting for us

  try {
    return async_scheduler->prun(async_sched::block);
  }
  catch (flx_exception_t &x) { return - flx_exception_handler (&x); }
  catch (std::exception &x) { return - std_exception_handler (&x); }
  catch (int &x) { fprintf (stderr, "Exception type int: %d\n", x); return -x; }
  catch (::std::string &x) { fprintf (stderr, "Exception type string : %s\n", x.c_str()); return -1; }
  catch (::flx::rtl::con_t &x) { fprintf (stderr, "Rogue continuatiuon caught\n"); return -6; }
  catch (...) { fprintf(stderr, "[flx_world:run_until_complete] Unknown exception in thread!\n"); return -5; }
}


// TODO: factor into async_sched. run_felix_pthread_ctor does this twice
void flx_world::spawn_fthread(con_t *top) {
	fthread_t *ft = new (*gcp, _fthread_ptr_map, false) fthread_t(top);
  get_sync_scheduler()->push_new(ft);
}

void flx_world::external_multi_swrite (schannel_t *chan, void *data) 
{
  async_scheduler->external_multi_swrite (chan,data);
} 

}} // namespaces
