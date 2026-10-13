#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <cstdint>
using namespace godot;
class NativeRecipe : public Resource {
    GDCLASS(NativeRecipe, Resource)
    int64_t score = 0;
protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("set_score", "value"), &NativeRecipe::set_score);
        ClassDB::bind_method(D_METHOD("get_score"), &NativeRecipe::get_score);
        ClassDB::bind_method(D_METHOD("add", "delta"), &NativeRecipe::add);
        ADD_PROPERTY(PropertyInfo(Variant::INT, "score"), "set_score", "get_score");
        ADD_SIGNAL(MethodInfo("score_changed", PropertyInfo(Variant::INT, "score")));
    }
public:
    void set_score(int64_t value) {
        int64_t next = value < 0 ? 0 : (value > 100 ? 100 : value);
        if (score == next) return;
        score = next;
        emit_changed();
        emit_signal("score_changed", score);
    }
    int64_t get_score() const { return score; }
    int64_t add(int64_t delta) {
        // Godot integers are 64-bit. Compare before addition, including INT64_MIN/MAX.
        set_score(delta >= 100 - score ? 100 : (delta <= -score ? 0 : score + delta));
        return score;
    }
};
void initialize_recipe(ModuleInitializationLevel level) {
    if (level == MODULE_INITIALIZATION_LEVEL_SCENE) GDREGISTER_CLASS(NativeRecipe);
}
void terminate_recipe(ModuleInitializationLevel) {}
extern "C" GDExtensionBool GDE_EXPORT native_recipe_init(
        GDExtensionInterfaceGetProcAddress proc, GDExtensionClassLibraryPtr library,
        GDExtensionInitialization *initialization) {
    GDExtensionBinding::InitObject init(proc, library, initialization);
    init.register_initializer(initialize_recipe);
    init.register_terminator(terminate_recipe);
    init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
